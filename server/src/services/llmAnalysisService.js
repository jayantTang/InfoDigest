/**
 * LLM Analysis Service for v2.0
 * Generates AI-powered insights for strategies, focus items, and market events
 */

import logger from '../config/logger.js';
import { pool } from '../config/database.js';

class LLMAnalysisService {
  constructor() {
    this.provider = process.env.LLM_PROVIDER || 'deepseek';
    this.model = process.env.LLM_MODEL || 'deepseek-chat';
    this.apiKey = process.env.DEEPSEEK_API_KEY || process.env.OPENAI_API_KEY;
    this.baseUrl = this.provider === 'deepseek'
      ? 'https://api.deepseek.com'
      : 'https://api.openai.com';
  }

  /**
   * Call LLM API
   */
  async callLLM(systemPrompt, userPrompt) {
    try {
      // Import OpenAI SDK dynamically
      const OpenAI = (await import('openai')).default;

      const client = new OpenAI({
        apiKey: this.apiKey,
        baseURL: this.baseUrl,
      });

      logger.debug('Calling LLM API', {
        provider: this.provider,
        model: this.model,
      });

      const completion = await client.chat.completions.create({
        model: this.model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 2000,
      });

      const content = completion.choices[0].message.content;

      logger.debug('LLM API response received', {
        provider: this.provider,
        contentLength: content.length,
      });

      return content;
    } catch (error) {
      logger.error('LLM API call failed', {
        error: error.message,
        provider: this.provider,
      });
      throw error;
    }
  }

  /**
   * Generate analysis for triggered strategy
   */
  async generateStrategyAnalysis(strategy, marketData, triggerReason) {
    try {
      logger.info('Generating strategy analysis', {
        strategyId: strategy.id,
        symbol: strategy.symbol,
        conditionType: strategy.condition_type,
      });

      // Build context data
      const context = this.buildStrategyContext(strategy, marketData, triggerReason);

      // System prompt
      const systemPrompt = `你是一位专业的投资分析师，擅长解读股票市场信号和提供投资建议。

你的任务：
1. 分析策略触发的原因
2. 解释当前市场状况
3. 提供专业的投资建议
4. 使用简洁清晰的语言
5. 回复格式为JSON

输出格式（JSON）：
{
  "title": "简短标题（20字内）",
  "triggerReason": "触发原因的详细解释",
  "marketContext": "当前市场背景分析",
  "technicalAnalysis": "技术指标分析（如适用）",
  "riskAssessment": "风险评估",
  "actionSuggestion": "行动建议",
  "confidence": 0-100的置信度
}`;

      // User prompt
      const userPrompt = `请分析以下策略触发：

**策略信息：**
- 股票代码：${strategy.symbol}
- 策略名称：${strategy.name || '未命名'}
- 条件类型：${this.getConditionTypeName(strategy.condition_type)}
- 策略条件：${JSON.stringify(strategy.conditions, null, 2)}

**市场数据：**
${this.formatMarketData(marketData)}

**触发原因：**
${triggerReason}

请提供深入的分析和建议。`;

      // Call LLM
      const response = await this.callLLM(systemPrompt, userPrompt);

      // Parse JSON response
      const analysis = this.parseJSONResponse(response);

      // Save analysis to database
      await this.saveStrategyAnalysis(strategy.id, strategy.user_id, analysis, marketData);

      logger.info('Strategy analysis generated', {
        strategyId: strategy.id,
        title: analysis.title,
      });

      return analysis;
    } catch (error) {
      logger.error('Failed to generate strategy analysis', {
        error: error.message,
        strategyId: strategy.id,
      });

      // Return fallback analysis
      return this.getFallbackStrategyAnalysis(strategy, marketData, triggerReason);
    }
  }

  /**
   * Generate analysis for temporary focus item
   */
  async generateFocusAnalysis(focusItem, findings) {
    try {
      logger.info('Generating focus analysis', {
        focusItemId: focusItem.id,
        title: focusItem.title,
      });

      // System prompt
      const systemPrompt = `你是一位专业的投资分析师，擅长总结市场监控发现并提供行动建议。

你的任务：
1. 总结监控期间的重要发现
2. 分析价格走势和相关性
3. 提供基于发现的行动建议
4. 使用简洁清晰的语言
5. 回复格式为JSON

输出格式（JSON）：
{
  "title": "简短标题（20字内）",
  "summary": "监控期间发现的总结",
  "keyFindings": ["发现1", "发现2", "发现3"],
  "priceAnalysis": "价格走势分析",
  "correlationAnalysis": "相关性分析（如适用）",
  "actionSuggestions": ["建议1", "建议2", "建议3"],
  "riskLevel": "low/medium/high",
  "confidence": 0-100的置信度
}`;

      // User prompt
      const userPrompt = `请分析以下临时关注项目的监控结果：

**关注项目：**
- 标题：${focusItem.title}
- 描述：${focusItem.description || '无'}
- 目标标的：${JSON.stringify(focusItem.targets, null, 2)}
- 关注重点：${JSON.stringify(focusItem.focus, null, 2)}
- 监控期间：${focusItem.created_at} 至 ${new Date().toISOString()}

**监控发现：**
${this.formatFindings(findings)}

请提供深入的分析和建议。`;

      // Call LLM
      const response = await this.callLLM(systemPrompt, userPrompt);

      // Parse JSON response
      const analysis = this.parseJSONResponse(response);

      // Save analysis to database
      await this.saveFocusAnalysis(focusItem.id, focusItem.user_id, analysis, findings);

      logger.info('Focus analysis generated', {
        focusItemId: focusItem.id,
        title: analysis.title,
      });

      return analysis;
    } catch (error) {
      logger.error('Failed to generate focus analysis', {
        error: error.message,
        focusItemId: focusItem.id,
      });

      // Return fallback analysis
      return this.getFallbackFocusAnalysis(focusItem, findings);
    }
  }

  /**
   * Generate analysis for market event
   */
  async generateEventAnalysis(event, affectedSymbols = []) {
    try {
      logger.info('Generating event analysis', {
        eventId: event.id,
        title: event.title,
      });

      // Get market data for affected symbols
      const marketDataContext = [];

      for (const symbol of affectedSymbols.slice(0, 5)) { // Limit to 5 symbols
        try {
          const marketData = await this.getMarketData(symbol);
          marketDataContext.push({
            symbol,
            ...marketData,
          });
        } catch (error) {
          logger.warn(`Failed to get market data for ${symbol}`, {
            error: error.message,
          });
        }
      }

      // System prompt
      const systemPrompt = `你是一位专业的财经分析师，擅长解读市场事件和评估其影响。

你的任务：
1. 深度分析市场事件
2. 评估对相关标的的影响
3. 提供未来展望
4. 使用专业但易懂的语言
5. 回复格式为JSON

输出格式（JSON）：
{
  "title": "简短标题（20字内）",
  "eventSummary": "事件概述",
  "impactAnalysis": "影响分析",
  "affectedAssets": ["受影响标的1", "受影响标的2"],
  "marketReaction": "市场反应分析",
  "futureOutlook": "未来展望",
  "keyTakeaways": ["要点1", "要点2", "要点3"],
  "severity": "low/medium/high",
  "confidence": 0-100的置信度
}`;

      // User prompt
      const userPrompt = `请分析以下市场事件：

**事件信息：**
- 标题：${event.title}
- 描述：${event.description || '无'}
- 分类：${event.category}
- 重要性评分：${event.importance_score}/100
- 相关标的：${event.symbols ? event.symbols.join(', ') : '无'}
- 相关板块：${event.sectors ? event.sectors.join(', ') : '无'}
- 发布时间：${event.published_at}
- 来源：${event.source}

**受影响标的市场数据：**
${this.formatMarketDataContext(marketDataContext)}

请提供深入的分析和评估。`;

      // Call LLM
      const response = await this.callLLM(systemPrompt, userPrompt);

      // Parse JSON response
      const analysis = this.parseJSONResponse(response);

      // Save analysis to database
      await this.saveEventAnalysis(event.id, analysis, marketDataContext);

      logger.info('Event analysis generated', {
        eventId: event.id,
        title: analysis.title,
      });

      return analysis;
    } catch (error) {
      logger.error('Failed to generate event analysis', {
        error: error.message,
        eventId: event.id,
      });

      // Return fallback analysis
      return this.getFallbackEventAnalysis(event);
    }
  }

  /**
   * Build strategy context for LLM
   */
  buildStrategyContext(strategy, marketData, triggerReason) {
    return {
      symbol: strategy.symbol,
      conditionType: strategy.condition_type,
      conditions: strategy.conditions,
      marketData: {
        price: marketData.price?.close_price,
        change: marketData.price?.change_percent,
        volume: marketData.price?.volume,
        technical: marketData.technical,
      },
      triggerReason,
    };
  }

  /**
   * Format market data for prompt
   */
  formatMarketData(marketData) {
    if (!marketData.price) {
      return '暂无市场数据';
    }

    let formatted = `- 当前价格：$${marketData.price.close_price?.toFixed(2) || 'N/A'}\n`;
    formatted += `- 涨跌幅：${marketData.price.change_percent?.toFixed(2) || 'N/A'}%\n`;
    formatted += `- 开盘价：$${marketData.price.open_price?.toFixed(2) || 'N/A'}\n`;
    formatted += `- 最高价：$${marketData.price.high_price?.toFixed(2) || 'N/A'}\n`;
    formatted += `- 最低价：$${marketData.price.low_price?.toFixed(2) || 'N/A'}\n`;
    formatted += `- 成交量：${marketData.price.volume?.toLocaleString() || 'N/A'}\n`;

    if (marketData.technical) {
      formatted += `\n**技术指标：**\n`;
      if (marketData.technical.rsi) {
        formatted += `- RSI：${marketData.technical.rsi.toFixed(1)}\n`;
      }
      if (marketData.technical.macd_histogram) {
        formatted += `- MACD柱状图：${marketData.technical.macd_histogram.toFixed(4)}\n`;
      }
      if (marketData.technical.bollinger_upper) {
        formatted += `- 布林带上轨：$${marketData.technical.bollinger_upper.toFixed(2)}\n`;
        formatted += `- 布林带中轨：$${marketData.technical.bollinger_middle.toFixed(2)}\n`;
        formatted += `- 布林带下轨：$${marketData.technical.bollinger_lower.toFixed(2)}\n`;
      }
    }

    return formatted;
  }

  /**
   * Format findings for prompt
   */
  formatFindings(findings) {
    if (!findings || findings.length === 0) {
      return '暂无监控发现';
    }

    let formatted = '';
    findings.forEach((finding, index) => {
      formatted += `${index + 1}. ${finding.type || '发现'}：${finding.description || '无详情'}\n`;
      if (finding.timestamp) {
        formatted += `   时间：${finding.timestamp}\n`;
      }
    });

    return formatted;
  }

  /**
   * Format market data context for prompt
   */
  formatMarketDataContext(marketDataContext) {
    if (!marketDataContext || marketDataContext.length === 0) {
      return '暂无市场数据';
    }

    let formatted = '';
    marketDataContext.forEach((data) => {
      formatted += `\n**${data.symbol}**\n`;
      if (data.price) {
        formatted += `- 价格：$${data.price.close_price?.toFixed(2) || 'N/A'}\n`;
        formatted += `- 涨跌幅：${data.price.change_percent?.toFixed(2) || 'N/A'}%\n`;
      }
    });

    return formatted;
  }

  /**
   * Get condition type name in Chinese
   */
  getConditionTypeName(conditionType) {
    const names = {
      price: '价格条件',
      technical: '技术指标',
      news: '新闻事件',
      time: '时间条件',
    };
    return names[conditionType] || conditionType;
  }

  /**
   * Parse JSON response from LLM
   */
  parseJSONResponse(response) {
    try {
      // Try to extract JSON from response
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      // If no JSON found, return simple object
      return {
        title: '分析完成',
        content: response,
      };
    } catch (error) {
      logger.error('Failed to parse JSON response', {
        error: error.message,
        response,
      });
      return {
        title: '分析完成',
        content: response,
      };
    }
  }

  /**
   * Get market data for symbol
   */
  async getMarketData(symbol) {
    try {
      const [priceResult, techResult] = await Promise.all([
        pool.query('SELECT * FROM prices WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1', [symbol]),
        pool.query('SELECT * FROM technical_indicators WHERE symbol = $1 ORDER BY calculated_at DESC LIMIT 1', [symbol]),
      ]);

      return {
        price: priceResult.rows[0] || null,
        technical: techResult.rows[0] || null,
      };
    } catch (error) {
      logger.error('Failed to get market data', {
        error: error.message,
        symbol,
      });
      return {};
    }
  }

  /**
   * Save strategy analysis to database
   */
  async saveStrategyAnalysis(strategyId, userId, analysis, marketData) {
    try {
      const query = `
        INSERT INTO strategy_analyses (
          strategy_id,
          user_id,
          title,
          trigger_reason,
          market_context,
          technical_analysis,
          risk_assessment,
          action_suggestion,
          confidence,
          analysis_data,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
      `;

      await pool.query(query, [
        strategyId,
        userId,
        analysis.title,
        analysis.triggerReason || '',
        analysis.marketContext || '',
        analysis.technicalAnalysis || '',
        analysis.riskAssessment || '',
        analysis.actionSuggestion || '',
        analysis.confidence || 50,
        JSON.stringify({
          ...analysis,
          marketData,
        }),
      ]);

      logger.debug('Strategy analysis saved', { strategyId, userId });
    } catch (error) {
      logger.error('Failed to save strategy analysis', {
        error: error.message,
        strategyId,
      });
    }
  }

  /**
   * Save focus analysis to database
   */
  async saveFocusAnalysis(focusItemId, userId, analysis, findings) {
    try {
      const query = `
        INSERT INTO focus_analyses (
          focus_item_id,
          user_id,
          title,
          summary,
          key_findings,
          price_analysis,
          correlation_analysis,
          action_suggestions,
          risk_level,
          confidence,
          analysis_data,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, CURRENT_TIMESTAMP)
      `;

      await pool.query(query, [
        focusItemId,
        userId,
        analysis.title,
        analysis.summary || '',
        JSON.stringify(analysis.keyFindings || []),
        analysis.priceAnalysis || '',
        analysis.correlationAnalysis || '',
        JSON.stringify(analysis.actionSuggestions || []),
        analysis.riskLevel || 'medium',
        analysis.confidence || 50,
        JSON.stringify({
          ...analysis,
          findings,
        }),
      ]);

      logger.debug('Focus analysis saved', { focusItemId, userId });
    } catch (error) {
      logger.error('Failed to save focus analysis', {
        error: error.message,
        focusItemId,
      });
    }
  }

  /**
   * Save event analysis to database
   */
  async saveEventAnalysis(eventId, analysis, marketDataContext) {
    try {
      const query = `
        INSERT INTO event_analyses (
          event_id,
          title,
          event_summary,
          impact_analysis,
          affected_assets,
          market_reaction,
          future_outlook,
          key_takeaways,
          severity,
          confidence,
          analysis_data,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, CURRENT_TIMESTAMP)
      `;

      await pool.query(query, [
        eventId,
        analysis.title,
        analysis.eventSummary || '',
        analysis.impactAnalysis || '',
        JSON.stringify(analysis.affectedAssets || []),
        analysis.marketReaction || '',
        analysis.futureOutlook || '',
        JSON.stringify(analysis.keyTakeaways || []),
        analysis.severity || 'medium',
        analysis.confidence || 50,
        JSON.stringify({
          ...analysis,
          marketDataContext,
        }),
      ]);

      logger.debug('Event analysis saved', { eventId });
    } catch (error) {
      logger.error('Failed to save event analysis', {
        error: error.message,
        eventId,
      });
    }
  }

  /**
   * Fallback strategy analysis when LLM fails
   */
  getFallbackStrategyAnalysis(strategy, marketData, triggerReason) {
    const conditionType = this.getConditionTypeName(strategy.condition_type);

    return {
      title: `${strategy.symbol} ${conditionType}触发`,
      triggerReason: `您的${conditionType}策略已触发。${triggerReason}`,
      marketContext: marketData.price
        ? `当前价格为 $${marketData.price.close_price?.toFixed(2)}，涨跌幅为 ${marketData.price.change_percent?.toFixed(2)}%`
        : '暂无市场数据',
      technicalAnalysis: '技术分析数据暂时不可用',
      riskAssessment: 'medium',
      actionSuggestion: '建议关注后续走势，结合其他指标综合判断',
      confidence: 50,
    };
  }

  /**
   * Fallback focus analysis when LLM fails
   */
  getFallbackFocusAnalysis(focusItem, findings) {
    const findingsCount = findings?.length || 0;

    return {
      title: `${focusItem.title} - 监控报告`,
      summary: `监控期间共发现 ${findingsCount} 个重要事件`,
      keyFindings: findings?.slice(0, 3).map((f) => f.description || '发现') || ['暂无发现'],
      priceAnalysis: '价格分析数据暂时不可用',
      correlationAnalysis: '相关性分析数据暂时不可用',
      actionSuggestions: ['建议继续关注相关标的', '注意风险控制'],
      riskLevel: 'medium',
      confidence: 50,
    };
  }

  /**
   * Fallback event analysis when LLM fails
   */
  getFallbackEventAnalysis(event) {
    return {
      title: event.title.substring(0, 20),
      eventSummary: event.description || event.title,
      impactAnalysis: `此事件重要性评分为 ${event.importance_score}/100`,
      affectedAssets: event.symbols || [],
      marketReaction: '市场反应分析暂时不可用',
      futureOutlook: '建议密切关注后续发展',
      keyTakeaways: [
        `事件分类：${event.category}`,
        `重要性评分：${event.importance_score}`,
      ],
      severity: event.importance_score >= 80 ? 'high' : event.importance_score >= 50 ? 'medium' : 'low',
      confidence: 50,
    };
  }
}

// Singleton instance
const llmAnalysisService = new LLMAnalysisService();

export default llmAnalysisService;
