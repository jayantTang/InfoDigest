/**
 * 创建测试数据脚本（简化版）
 * 用于演示投资机会功能
 */

import { pool } from '../config/database.js';
import { v4 as uuidv4 } from 'uuid';

async function createTestData() {
  console.log('开始创建测试数据...\n');

  try {
    // 1. 创建测试用户
    const userId = uuidv4();
    const timestamp = Date.now();
    const testEmail = `test_user_${timestamp}@example.com`;

    await pool.query(
      `INSERT INTO users (id, username, email)
       VALUES ($1, $2, $3)
       ON CONFLICT (id) DO NOTHING`,
      [userId, 'test_user', testEmail]
    );
    console.log('✓ 创建测试用户:', userId);

    // 2. 创建测试投资组合
    const portfolioSymbols = [
      { symbol: 'AAPL', shares: 100, avgCost: 150.00 },
      { symbol: 'TSLA', shares: 50, avgCost: 200.00 },
      { symbol: 'NVDA', shares: 30, avgCost: 400.00 }
    ];

    for (const item of portfolioSymbols) {
      const portfolioId = uuidv4();
      await pool.query(
        `INSERT INTO portfolios (id, user_id, symbol, asset_type, shares, avg_cost, current_price, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT DO NOTHING`,
        [portfolioId, userId, item.symbol, 'stock', item.shares, item.avgCost, item.avgCost * 1.1, 'active']
      );
      console.log(`✓ 添加持仓: ${item.symbol}`);
    }

    // 3. 创建价格监控策略
    const strategies = [
      {
        name: 'AAPL突破策略',
        symbol: 'AAPL',
        condition: 'price_above',
        targetPrice: 180.00,
        action: 'buy'
      },
      {
        name: 'TSLA抄底策略',
        symbol: 'TSLA',
        condition: 'price_below',
        targetPrice: 180.00,
        action: 'buy'
      }
    ];

    const createdStrategies = [];
    for (const strategy of strategies) {
      const strategyId = uuidv4();
      await pool.query(
        `INSERT INTO strategies (id, user_id, name, symbol, condition_type, conditions, action, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT DO NOTHING`,
        [strategyId, userId, strategy.name, strategy.symbol, strategy.condition,
         JSON.stringify({ target_price: strategy.targetPrice }),
         JSON.stringify({ type: strategy.action }),
         'active']
      );
      createdStrategies.push({ ...strategy, id: strategyId });
      console.log(`✓ 创建策略: ${strategy.name}`);
    }

    // 4. 创建模拟市场事件
    const events = [
      {
        title: '美联储宣布维持利率不变',
        description: '美联储在最新的FOMC会议上宣布维持基准利率不变，符合市场预期。主席鲍威尔表示将继续关注通胀数据。',
        category: 'macro',
        importance: 85,
        source: 'Bloomberg'
      },
      {
        title: 'AAPL发布新一代iPhone',
        description: '苹果公司今日正式发布新一代iPhone，搭载更强大的A18芯片和升级的摄像头系统。',
        category: 'product',
        importance: 78,
        source: 'TechCrunch'
      },
      {
        title: '特斯拉Q4交付量超预期',
        description: '特斯拉公布第四季度交付数据，总交付量达到48.5万辆，超出市场预期的45万辆。',
        category: 'earnings',
        importance: 82,
        source: 'Reuters'
      }
    ];

    for (const event of events) {
      const eventId = uuidv4();
      await pool.query(
        `INSERT INTO news_events (id, title, description, category, importance_score, source, published_at, is_processed)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT DO NOTHING`,
        [eventId, event.title, event.description, event.category,
         event.importance, event.source, new Date(), false]
      );
      console.log(`✓ 添加事件: ${event.title} (${event.importance}分)`);
    }

    // 5. 生成策略分析报告
    const strategyAnalyses = [
      {
        strategyIndex: 0, // AAPL突破策略
        triggerReason: 'AAPL价格突破$180阻力位',
        marketContext: '科技股整体走强，纳斯达克指数上涨1.5%',
        technicalAnalysis: 'RSI指标显示强势，MACD金叉',
        riskAssessment: '中等风险，建议控制仓位',
        actionSuggestion: '建议建立多头仓位，目标价位$195',
        confidence: 85
      },
      {
        strategyIndex: 1, // TSLA抄底策略
        triggerReason: 'TSLA价格回落至支撑位$180附近',
        marketContext: '电动车板块调整，但长期基本面未变',
        technicalAnalysis: 'RSI指标显示超卖，成交量萎缩',
        riskAssessment: '中等风险，分批建仓',
        actionSuggestion: '建议分批建仓，设置止损$170',
        confidence: 72
      }
    ];

    for (const analysis of strategyAnalyses) {
      const strategy = createdStrategies[analysis.strategyIndex];
      const analysisId = uuidv4();

      await pool.query(
        `INSERT INTO strategy_analyses
         (id, strategy_id, user_id, title, trigger_reason, market_context,
          technical_analysis, risk_assessment, action_suggestion, confidence, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [analysisId, strategy.id, userId,
         `${strategy.name}触发`,
         analysis.triggerReason,
         analysis.marketContext,
         analysis.technicalAnalysis,
         analysis.riskAssessment,
         analysis.actionSuggestion,
         analysis.confidence,
         new Date()]
      );
      console.log(`✓ 生成策略分析: ${strategy.name}`);
    }

    // 6. 生成关注分析报告（直接创建，不依赖temporary_focus）
    const focusAnalyses = [
      {
        symbol: 'MSFT',
        title: 'MSFT技术面分析',
        summary: '微软股价技术面强势突破，云计算业务增长强劲',
        keyFindings: ['突破200日均线', '成交量放大', 'RSI指标健康'],
        actionSuggestions: ['可考虑适量建仓', '关注Azure业务增长'],
        riskLevel: 'medium',
        confidence: 75
      },
      {
        symbol: 'GOOGL',
        title: 'GOOGL基本面分析',
        summary: '谷歌面临监管压力但基本面稳健，AI业务布局领先',
        keyFindings: ['估值处于历史低位', '广告收入恢复增长', 'AI业务布局领先'],
        actionSuggestions: ['长期投资者可逢低吸纳', '短期注意波动风险'],
        riskLevel: 'low',
        confidence: 68
      }
    ];

    for (const analysis of focusAnalyses) {
      // 先创建对应的temporary_focus记录
      const focusId = uuidv4();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

      await pool.query(
        `INSERT INTO temporary_focus (id, user_id, title, targets, focus, expires_at, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT DO NOTHING`,
        [focusId, userId, `${analysis.symbol}关注分析`,
         JSON.stringify({ symbols: [analysis.symbol] }),
         '{"news": true, "price": true}',
         expiresAt, 'monitoring']
      );

      // 然后创建分析报告
      const analysisId = uuidv4();
      await pool.query(
        `INSERT INTO focus_analyses (id, focus_item_id, user_id, title, summary,
         key_findings, action_suggestions, risk_level, confidence, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [analysisId, focusId, userId, analysis.title, analysis.summary,
         JSON.stringify(analysis.keyFindings),
         JSON.stringify(analysis.actionSuggestions),
         analysis.riskLevel,
         analysis.confidence, new Date()]
      );
      console.log(`✓ 生成关注分析: ${analysis.symbol}`);
    }

    console.log('\n✅ 测试数据创建完成！');
    console.log('\n数据汇总:');
    console.log(`- 用户ID: ${userId}`);
    console.log(`- 投资组合: ${portfolioSymbols.length}个持仓`);
    console.log(`- 监控策略: ${strategies.length}个策略`);
    console.log(`- 市场事件: ${events.length}个事件`);
    console.log(`- 策略分析: ${strategyAnalyses.length}份报告`);
    console.log(`- 关注分析: ${focusAnalyses.length}份报告`);

    console.log('\n现在可以在iOS App中查看投资机会了！');
    console.log('\n测试用户ID（用于iOS查询）:', userId);

  } catch (error) {
    console.error('创建测试数据失败:', error);
    throw error;
  }
}

// 如果直接运行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
  createTestData()
    .then(() => {
      console.log('\n脚本执行完成');
      process.exit(0);
    })
    .catch(error => {
      console.error('脚本执行失败:', error);
      process.exit(1);
    });
}

export { createTestData };
