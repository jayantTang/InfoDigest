# DeepSeek API 配置说明

本项目已默认配置使用 **DeepSeek API** 作为LLM服务提供商。

## 为什么选择DeepSeek？

### 优势

1. **超高性价比**
   - 输入：¥1/百万tokens
   - 输出：¥2/百万tokens
   - 相比OpenAI GPT-4节省90%以上成本

2. **优秀的中文理解**
   - 专为中文优化
   - 更好的语义理解能力
   - 符合中文表达习惯

3. **与OpenAI兼容**
   - 使用相同的SDK（`openai` npm包）
   - 兼容的API格式
   - 无缝切换无需修改大量代码

4. **稳定性高**
   - 国内服务，访问稳定
   - 响应速度快

## 当前配置

项目已配置DeepSeek API：

```env
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=sk-7b132ad9641e45a088beeb8b6520a0fb
```

## 如何使用

### 开箱即用

项目已配置好DeepSeek API，直接启动服务器即可：

```bash
cd server
npm install
npm run migrate  # 初始化数据库
npm run dev      # 启动服务器
```

### 切换到OpenAI（可选）

如果需要使用OpenAI，修改 `.env` 文件：

```env
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
OPENAI_API_KEY=your_openai_api_key
```

重启服务器后生效。

### 切换到其他模型

DeepSeek支持多个模型：

```env
# DeepSeek-Chat（推荐，平衡性能和成本）
LLM_MODEL=deepseek-chat

# DeepSeek-Coder（代码优化）
LLM_MODEL=deepseek-coder

# DeepSeek-V3（最新模型）
LLM_MODEL=deepseek-v3
```

## API调用示例

### 新闻摘要生成

```javascript
import { generateNewsDigest } from './services/llmProcessor.js';

const newsData = {
  data: [
    { title: "AI技术突破", description: "...", url: "..." }
  ]
};

const digest = await generateNewsDigest(newsData);
// 返回：{ title, summary, content, links }
```

### 股票市场分析

```javascript
import { generateStockSummary } from './services/llmProcessor.js';

const stockData = {
  data: [
    { symbol: "AAPL", price: 150, changePercent: "+2.5%" }
  ]
};

const summary = await generateStockSummary(stockData);
// 返回：{ title, summary, content }
```

### 综合摘要生成

```javascript
import { generateDigest } from './services/llmProcessor.js';

const digest = await generateDigest(newsData, stockData);
// 返回：{ title, summary, content, images, links }
```

## 定价对比

| 服务商 | 输入价格 | 输出价格 | 相对成本 |
|--------|---------|---------|---------|
| DeepSeek | ¥1/M tokens | ¥2/M tokens | 1x |
| OpenAI GPT-4o-mini | $0.15/M | $0.60/M | ~30x |
| OpenAI GPT-4o | $2.50/M | $10/M | ~250x |

*按汇率1USD=7CNY计算*

## 配额检查

### 查看API余额

访问 [DeepSeek开放平台](https://platform.deepseek.com/) 查看余额和使用情况。

### 本地监控

服务器日志会记录每次API调用：

```bash
# 查看实时日志
tail -f server/logs/combined.log | grep "LLM API"
```

## 常见问题

### Q: API调用失败怎么办？

**A**: 检查以下几点：
1. API Key是否正确
2. 账户是否有余额
3. 网络连接是否正常
4. 查看服务器错误日志

### Q: 如何限制使用量？

**A**: 可以在 `llmProcessor.js` 中添加请求频率限制，或设置最大tokens：

```javascript
max_tokens: 1000, // 降低每次请求的最大token数
```

### Q: 支持多语言吗？

**A**: DeepSeek对中文优化最好，但也支持英文和其他语言。

### Q: 如何测试API是否正常？

**A**: 启动服务器后手动触发摘要生成：

```bash
curl -X POST http://localhost:3000/api/admin/run-digest
```

查看日志确认API调用成功。

## 技术支持

- DeepSeek官方文档：https://platform.deepseek.com/api-docs/
- GitHub Issues：提交项目问题
- DeepSeek社区：https://github.com/deepseek-ai

## 更新日志

- **2024-01**: 项目默认配置DeepSeek API
- 支持多个LLM提供商切换
- 优化中文提示词
- 添加自动降级机制
