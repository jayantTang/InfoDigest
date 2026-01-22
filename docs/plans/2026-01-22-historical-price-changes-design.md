# 历史涨跌幅功能设计文档

**日期**: 2026-01-22
**作者**: Claude & User
**状态**: 已批准

## 概述

在经济指标页面为每个指数添加历史涨跌幅数据显示，涵盖6个时间段：1天、1周、1月、3月、1年、3年。

## 需求总结

### 功能需求
- 在每个指数卡片上一行显示6个时间段的涨跌幅
- 使用不同颜色区分涨跌（红色涨、绿色跌）
- 显示1位小数，带符号（+2.5% / -1.2%）

### 非功能需求
- 后端采集历史数据，避免前端重复请求
- API响应时间 < 500ms
- iOS端加载时间 < 2秒
- 支持数据不足时的优雅降级

## 数据层设计

### 数据库schema

现有 `prices` 表结构保持不变，添加索引优化：

```sql
CREATE INDEX idx_prices_symbol_timestamp ON prices(symbol, timestamp DESC);
```

### 数据采集策略

**采集频率**: 每天收盘后采集一次
- A股：15:30 采集
- 美股：05:00 采集（次日）

**数据保留**: 保留最近3年历史数据

**定时任务**: 使用 `node-crontab` 设置每天采集任务

## 后端服务设计

### 新增文件

**文件**: `server/src/services/priceChangeCalculator.js`

**核心类**: `PriceChangeCalculator`

```javascript
class PriceChangeCalculator {
  /**
   * 计算某个符号在各个时间段的涨跌幅
   * @param {string} symbol - 指数代码
   * @returns {Object} - 各时间段涨跌幅
   */
  async calculatePriceChange(symbol, timestamp) {
    const periods = {
      '1d': 1, '1w': 7, '1m': 30,
      '3m': 90, '1y': 365, '3y': 1095
    };

    const changes = {};
    const currentPrice = await this.getLatestPrice(symbol);

    for (const [period, days] of Object.entries(periods)) {
      const pastPrice = await this.getPriceAt(symbol, days);
      if (pastPrice && pastPrice > 0) {
        const changePercent = ((currentPrice - pastPrice) / pastPrice) * 100;
        changes[period] = {
          value: changePercent.toFixed(1),
          available: true
        };
      } else {
        changes[period] = { available: false };
      }
    }

    return changes;
  }

  /**
   * 获取N天前的价格
   */
  async getPriceAt(symbol, daysAgo) {
    const query = `
      SELECT close_price
      FROM prices
      WHERE symbol = $1
        AND timestamp >= NOW() - INTERVAL '${daysAgo} days'
        AND is_estimated = false
      ORDER BY timestamp ASC
      LIMIT 1
    `;

    const result = await pool.query(query, [symbol]);
    return result.rows[0]?.close_price || null;
  }

  /**
   * 获取最新价格
   */
  async getLatestPrice(symbol) {
    const query = `
      SELECT close_price
      FROM prices
      WHERE symbol = $1
      ORDER BY timestamp DESC
      LIMIT 1
    `;

    const result = await pool.query(query, [symbol]);
    return parseFloat(result.rows[0].close_price);
  }
}
```

### API端点

**路由**: `GET /api/economic-indicators/:symbol/history`

**响应格式**:
```json
{
  "success": true,
  "data": {
    "symbol": "000001.SS",
    "changes": {
      "1d": { "value": "+2.5", "available": true },
      "1w": { "value": "-0.8", "available": true },
      "1m": { "value": "+5.3", "available": true },
      "3m": { "value": "+12.4", "available": true },
      "1y": { "value": "-3.2", "available": true },
      "3y": { "value": "+25.7", "available": true }
    }
  }
}
```

## iOS前端设计

### 数据模型扩展

**文件**: `InfoDigest/InfoDigest/Models/EconomicIndicator.swift`

```swift
struct IndexData: Identifiable, Codable {
    // ... 现有字段

    // 新增字段
    let priceChanges: PriceChanges?

    struct PriceChanges: Codable {
        let oneDay: ChangeData?
        let oneWeek: ChangeData?
        let oneMonth: ChangeData?
        let threeMonths: ChangeData?
        let oneYear: ChangeData?
        let threeYears: ChangeData?

        struct ChangeData: Codable {
            let value: String      // "+2.5"
            let available: Bool
        }
    }
}
```

### UI组件

**文件**: `InfoDigest/InfoDigest/Views/EconomicIndicatorView.swift`

**新增组件**: `PriceChangeLabel`

```swift
struct PriceChangeLabel: View {
    let period: String      // "1天"
    let changeData: IndexData.PriceChanges.ChangeData?

    var body: some View {
        HStack(spacing: 2) {
            Text(period)
                .font(.caption2)
                .foregroundColor(.secondary)

            if let data = changeData, data.available {
                Text(data.value + "%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForValue(data.value))
            } else {
                Text("N/A")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.systemGray6))
        .cornerRadius(4)
        .opacity(changeData?.available == true ? 1.0 : 0.6)
    }

    private func colorForValue(_ value: String) -> Color {
        if value.hasPrefix("+") {
            return .red  // 涨
        } else if value.hasPrefix("-") {
            return .green  // 跌
        } else {
            return .secondary
        }
    }
}
```

**IndexCard布局更新**:

```swift
struct IndexCard: View {
    let index: IndexData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 现有的名称、代码、价格、时间显示
            // ...

            // 新增：涨跌幅显示区域
            if let changes = index.priceChanges {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 6) {
                    PriceChangeLabel(period: "1天", changeData: changes.oneDay)
                    PriceChangeLabel(period: "1周", changeData: changes.oneWeek)
                    PriceChangeLabel(period: "1月", changeData: changes.oneMonth)
                    PriceChangeLabel(period: "3月", changeData: changes.threeMonths)
                    PriceChangeLabel(period: "1年", changeData: changes.oneYear)
                    PriceChangeLabel(period: "3年", changeData: changes.threeYears)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(index.isStale ? Color.orange : Color.clear, lineWidth: 1)
        )
    }
}
```

### ViewModel更新

**文件**: `InfoDigest/InfoDigest/ViewModels/EconomicIndicatorViewModel.swift`

```swift
func loadIndicators() async {
    isRefreshing = true
    errorMessage = nil

    do {
        // 阶段1: 加载基础指标数据
        let indicators = try await apiService.getEconomicIndicators()

        // 阶段2: 异步加载历史涨跌幅
        await withTaskGroup(of: (String, IndexData.PriceChanges?).self) { group in
            // 为所有指数创建异步任务
            for index in indicators.allIndices {
                group.addTask {
                    do {
                        let changes = try await apiService.getHistoricalChanges(symbol: index.symbol)
                        return (index.symbol, changes)
                    } catch {
                        print("Failed to load changes for \(index.symbol): \(error)")
                        return (index.symbol, nil)
                    }
                }
            }

            // 收集结果
            var changesMap: [String: IndexData.PriceChanges] = [:]
            for await (symbol, changes) in group {
                if let changes = changes {
                    changesMap[symbol] = changes
                }
            }

            // 更新数据
            aStockIndices = indicators.aStockIndices.map { index in
                var updated = index
                updated.priceChanges = changesMap[index.symbol]
                return updated
            }

            // 同样处理其他指数类型...
        }

        lastUpdateTime = Date()
        isLoading = false

    } catch {
        errorMessage = "加载失败: \(error.localizedDescription)"
        isLoading = false
    }

    isRefreshing = false
}
```

### API服务扩展

**文件**: `InfoDigest/InfoDigest/Services/APIService.swift`

```swift
func getHistoricalChanges(symbol: String) async throws -> IndexData.PriceChanges {
    let endpoint = "/api/economic-indicators/\(symbol)/history"
    let response: HistoricalChangesResponse = try await performRequest(endpoint: endpoint)
    return response.data
}

struct HistoricalChangesResponse: Codable {
    let success: Bool
    let data: IndexData.PriceChanges
}
```

## 布局示例

```
┌───────────────────────────────────────┐
│ 上证指数        000001.SS      [估算]  │
│ 3200.50                    刚刚       │
│                                       │
│ 1天:↑+2.5% │1周:↓-0.8% │1月:↑+5.3%  │
│ 3月:↑+12.4%│1年:↓-3.2%│3年:↑+25.7%  │
└───────────────────────────────────────┘
```

## 错误处理

### 数据不足情况
- 显示 "N/A" 并降低透明度
- 不影响主界面显示

### API失败情况
- 主界面正常显示当前价格
- 涨跌幅区域显示占位符或隐藏
- 静默重试3次，超时5秒

### 异常值处理
```javascript
if (Math.abs(changePercent) > 100) {
  logger.warn('异常涨跌幅', { symbol, changePercent });
  // 可以选择标记为不可用
}
```

## 测试计划

### 单元测试
1. `PriceChangeCalculator` 各方法测试
2. 边界情况：数据不足、零值、负值
3. 性能测试：查询响应时间

### 集成测试
1. API端点测试
2. 数据库查询测试
3. 与现有采集器集成测试

### UI测试
1. 6个时间段标签布局测试
2. 不同屏幕尺寸适配测试
3. 颜色显示正确性测试
4. 数据不足时占位符测试

### 性能测试
1. API响应时间 < 500ms
2. iOS端加载时间 < 2秒
3. 内存占用增加 < 20MB

## 实施步骤

### Phase 1: 后端基础设施（第1天）
1. 创建 `priceChangeCalculator.js`
2. 添加数据库索引
3. 实现历史价格查询方法
4. 单元测试

### Phase 2: API端点（第1天）
1. 创建历史涨跌幅API路由
2. 集成到 `economicIndicators.js`
3. API测试

### Phase 3: iOS数据模型（第2天）
1. 扩展 `IndexData` 模型
2. 更新 `APIService`
3. 单元测试

### Phase 4: iOS UI实现（第2天）
1. 创建 `PriceChangeLabel` 组件
2. 更新 `IndexCard` 布局
3. 更新 `ViewModel` 加载逻辑
4. UI测试

### Phase 5: 集成测试与优化（第3天）
1. 端到端测试
2. 性能优化
3. 错误处理验证
4. 部署到iPhone测试

## 文件清单

### 需要创建的文件（2个）
1. `server/src/services/priceChangeCalculator.js` - 涨跌幅计算服务
2. `server/src/routes/historicalChanges.js` - API路由

### 需要修改的文件（5个）
3. `server/src/config/database.js` - 添加索引创建
4. `server/src/routes/economicIndicators.js` - 集成历史涨跌幅API
5. `InfoDigest/InfoDigest/Models/EconomicIndicator.swift` - 扩展数据模型
6. `InfoDigest/InfoDigest/ViewModels/EconomicIndicatorViewModel.swift` - 添加加载逻辑
7. `InfoDigest/InfoDigest/Views/EconomicIndicatorView.swift` - 更新UI组件
8. `InfoDigest/InfoDigest/Services/APIService.swift` - 添加API方法

## 技术风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 历史数据不足 | 高 | 中 | 优雅降级，显示N/A |
| API性能问题 | 中 | 中 | 添加缓存，优化查询 |
| UI布局在小屏幕拥挤 | 低 | 低 | 使用自适应字体 |
| 数据采集失败 | 中 | 低 | 定时任务监控和告警 |

## 成功标准

✅ **必须实现**:
- 6个时间段涨跌幅正常显示
- 涨跌颜色正确（红涨绿跌）
- 1位小数 + 符号格式
- 数据不足时显示N/A

✅ **质量标准**:
- API响应时间 < 500ms
- iOS加载时间 < 2秒
- 不影响现有功能
- 代码遵循现有架构
