import OpenAI from 'openai';
import config from '../config/index.js';
import logger from '../config/logger.js';

// Initialize LLM client based on configuration
let llmClient = null;
let currentModel = null;

function initializeLLMClient() {
  const provider = config.llm.provider;
  let apiKey, baseURL;

  switch (provider) {
    case 'deepseek':
      apiKey = config.apiKeys.deepseek;
      baseURL = config.llm.deepseekBaseUrl;
      currentModel = config.llm.model || 'deepseek-chat';
      break;
    case 'openai':
      apiKey = config.apiKeys.openai;
      baseURL = undefined; // Use default OpenAI URL
      currentModel = config.llm.model || 'gpt-4o-mini';
      break;
    default:
      logger.warn(`Unknown LLM provider: ${provider}, falling back to deepseek`);
      apiKey = config.apiKeys.deepseek;
      baseURL = config.llm.deepseekBaseUrl;
      currentModel = 'deepseek-chat';
  }

  if (apiKey) {
    llmClient = new OpenAI({
      apiKey,
      baseURL,
    });
    logger.info('LLM client initialized', { provider, model: currentModel });
  } else {
    logger.warn('No LLM API key configured, using fallback mode');
  }
}

// Initialize on module load
initializeLLMClient();

/**
 * Generic LLM completion function
 */
async function callLLM(systemPrompt, userPrompt, maxTokens = 1500) {
  if (!llmClient) {
    throw new Error('LLM client not configured');
  }

  logger.info('Calling LLM API', { model: currentModel, provider: config.llm.provider });

  const completion = await llmClient.chat.completions.create({
    model: currentModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    temperature: 0.7,
    max_tokens: maxTokens,
    response_format: { type: 'json_object' },
  });

  return completion.choices[0].message.content;
}

/**
 * Process data with LLM to generate rich content digest
 */
export async function generateDigest(newsData, stockData) {
  if (!llmClient) {
    logger.warn('LLM not configured, using fallback digest generation');
    return generateFallbackDigest(newsData, stockData);
  }

  try {
    const prompt = buildPrompt(newsData, stockData);
    const systemPrompt = `你是一个专业信息编辑和分析师。你的任务是：
1. 选择最重要和最有趣的新闻
2. 分析股票市场走势并识别关键趋势
3. 创建简洁、格式良好的Markdown摘要
4. 提取相关图片和链接

请以JSON格式返回，包含以下字段：
- title: 吸引人的标题
- summary: 1-2句话的推送通知摘要
- content: 完整的markdown内容，包含新闻、股票和分析部分
- images: 相关图片URL数组（如果源数据中有）
- links: 重要链接数组，包含标题和URL

保持内容简洁但信息丰富。使用表情符号使其更生动。`;

    const responseText = await callLLM(systemPrompt, prompt, 2000);
    const result = JSON.parse(responseText);

    logger.info('LLM digest generated successfully', {
      title: result.title,
      contentLength: result.content?.length,
    });

    return {
      messageType: 'digest',
      ...result,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error('LLM processing failed', { error: error.message });
    throw new Error(`LLM processing failed: ${error.message}`);
  }
}

/**
 * Generate a news-only digest
 */
export async function generateNewsDigest(newsData) {
  if (!llmClient) {
    return generateFallbackNewsDigest(newsData);
  }

  try {
    const prompt = formatNewsData(newsData);
    const systemPrompt = `你是一个新闻编辑。请用Markdown格式创建一个引人入胜的新闻摘要。

请以JSON格式返回：
- title: 吸引人的标题
- summary: 1-2句话的推送通知摘要
- content: 完整的markdown新闻摘要，包含要点和关键亮点
- links: 重要文章链接数组

专注于最重要和最有趣的故事。使用表情符号增加吸引力。`;

    const responseText = await callLLM(systemPrompt, prompt, 1500);
    const result = JSON.parse(responseText);

    logger.info('News digest generated', { title: result.title });

    return {
      messageType: 'news',
      ...result,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error('News digest generation failed', { error: error.message });
    throw new Error(`News digest generation failed: ${error.message}`);
  }
}

/**
 * Generate a stock market summary
 */
export async function generateStockSummary(stockData) {
  if (!llmClient) {
    return generateFallbackStockSummary(stockData);
  }

  try {
    const prompt = formatStockData(stockData);
    const systemPrompt = `你是一个金融分析师。请用Markdown格式创建一个简洁的市场摘要。

请以JSON格式返回：
- title: 市场摘要标题
- summary: 1-2句话的推送通知摘要
- content: 完整的markdown分析，包含：
  - 市场概况
  - 关键股票（如相关，使用表格格式）
  - 趋势简要分析

使用表情符号，使其信息丰富但简洁。`;

    const responseText = await callLLM(systemPrompt, prompt, 1000);
    const result = JSON.parse(responseText);

    logger.info('Stock summary generated', { title: result.title });

    return {
      messageType: 'stock',
      ...result,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error('Stock summary generation failed', { error: error.message });
    throw new Error(`Stock summary generation failed: ${error.message}`);
  }
}

/**
 * Build the prompt for full digest generation
 */
function buildPrompt(newsData, stockData) {
  let prompt = '';

  // Add news data
  if (newsData?.data?.length > 0) {
    prompt += '## 新闻数据\n\n';
    newsData.data.slice(0, 10).forEach((article, index) => {
      prompt += `${index + 1}. ${article.title}\n`;
      if (article.description) {
        prompt += `   ${article.description}\n`;
      }
      if (article.url) {
        prompt += `   URL: ${article.url}\n`;
      }
      prompt += '\n';
    });
  }

  // Add stock data
  if (stockData?.data?.length > 0) {
    prompt += '\n## 股票数据\n\n';
    stockData.data.forEach((stock) => {
      prompt += `- ${stock.symbol}: $${stock.price} (${stock.changePercent} 变化)\n`;
    });
  }

  return prompt;
}

/**
 * Format news data for prompt
 */
function formatNewsData(newsData) {
  if (!newsData?.data?.length) return 'No news data available';

  let text = '';
  newsData.data.slice(0, 10).forEach((article, index) => {
    text += `${index + 1}. ${article.title}\n`;
    if (article.description) {
      text += `   ${article.description}\n`;
    }
    if (article.url) {
      text += `   URL: ${article.url}\n`;
    }
    text += '\n';
  });

  return text;
}

/**
 * Format stock data for prompt
 */
function formatStockData(stockData) {
  if (!stockData?.data?.length) return 'No stock data available';

  let text = '| 股票代码 | 价格 | 涨跌 | 成交量 |\n';
  text += '|---------|------|------|--------|\n';

  stockData.data.forEach((stock) => {
    text += `| ${stock.symbol} | $${stock.price} | ${stock.changePercent} | ${stock.volume} |\n`;
  });

  return text;
}

/**
 * Fallback: Generate a simple digest without LLM
 */
function generateFallbackDigest(newsData, stockData) {
  const sections = [];

  // News section
  if (newsData?.data?.length > 0) {
    sections.push('## 📰 今日要闻\n\n');
    newsData.data.slice(0, 5).forEach((article) => {
      sections.push(`**${article.title}**\n\n`);
      if (article.description) {
        sections.push(`${article.description}\n\n`);
      }
    });
  }

  // Stock section
  if (stockData?.data?.length > 0) {
    sections.push('\n## 📈 市场行情\n\n');
    sections.push('| 股票代码 | 价格 | 涨跌 |\n');
    sections.push('|---------|------|------|\n');
    stockData.data.forEach((stock) => {
      sections.push(`| ${stock.symbol} | $${stock.price} | ${stock.changePercent} |\n`);
    });
  }

  const links = [
    ...newsData?.data?.slice(0, 3).map((article) => ({
      title: article.title,
      url: article.url,
    })) || [],
  ];

  return {
    messageType: 'digest',
    title: '今日信息摘要',
    summary: '精选新闻与市场动态摘要',
    content: sections.join(''),
    links,
    generatedAt: new Date().toISOString(),
  };
}

function generateFallbackNewsDigest(newsData) {
  const sections = ['## 📰 新闻摘要\n\n'];

  newsData?.data?.slice(0, 5).forEach((article) => {
    sections.push(`**${article.title}**\n\n`);
    if (article.description) {
      sections.push(`${article.description}\n\n`);
    }
  });

  return {
    messageType: 'news',
    title: '最新新闻',
    summary: '今日重要新闻摘要',
    content: sections.join(''),
    links: newsData?.data?.slice(0, 3).map((article) => ({
      title: article.title,
      url: article.url,
    })) || [],
  };
}

function generateFallbackStockSummary(stockData) {
  let content = '## 📈 市场行情\n\n';
  content += '| 股票代码 | 价格 | 涨跌 |\n';
  content += '|---------|------|------|\n';
  stockData?.data?.forEach((stock) => {
    content += `| ${stock.symbol} | $${stock.price} | ${stock.changePercent} |\n`;
  });

  return {
    messageType: 'stock',
    title: '市场行情',
    summary: '最新股票市场动态',
    content,
  };
}

/**
 * Reinitialize the LLM client (for testing or config changes)
 */
export function reinitializeLLM() {
  initializeLLMClient();
}

/**
 * Export callLLM for other services to use
 */
export { callLLM };
