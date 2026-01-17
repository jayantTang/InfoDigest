# InfoDigest v2.0 架构设计文档

## 核心设计决策

1. **双通道推送**: 重要新闻即时推送 + 定时深度摘要
2. **内容形式**: 深度浓缩的报告形式，支持多媒体
3. **个性化**: 用户偏好 + AI智能推荐
4. **数据保留**: 永久存储，支持搜索和历史回顾
5. **优先级**: 性能优先，所有设计以低延迟为目标

---

## 一、双通道推送系统

### 1.1 即时推送通道 (Breaking News)

**触发条件**:
```javascript
// 新闻重要性评分 >= 80/100
const IMPORTANCE_THRESHOLD = 80;

// 实时监控NewsAPI
// 每分钟检查一次
// 发现高重要性新闻立即推送
```

**实现架构**:
```
NewsAPI Webhook/轮询
  ↓
重要性评分引擎 (LLM评估)
  ↓
分数 >= 80?
  ↓ Yes
生成快速摘要
  ↓
立即推送到所有设备
```

**API设计**:
```javascript
POST /api/admin/check-breaking-news
// 每分钟调用一次

响应:
{
  "hasBreakingNews": true,
  "news": {
    "title": "OpenAI发布GPT-5",
    "importanceScore": 92,
    "category": "AI",
    "summary": "OpenAI今日正式发布...",
    "content": "深度分析内容..."
  }
}
```

### 1.2 定时摘要通道 (Daily/Weekly Digest)

**推送时间**:
- **每日摘要**: 每天晚上 9:00 (21:00)
- **周总结**: 每周日晚上 9:00
- **专题深度报告**: 每周 1-2 次（不定期）

**内容结构**:
```
## 每日科技简报 2025-01-17

### 🚨 重点关注 (即时推送回顾)
[今天已推送的重要新闻列表]

### 📊 深度分析 (核心内容)
#### 1. AI行业深度报告
[多角度分析、数据图表、趋势预测]
- 市场影响
- 专家观点
- 相关股票表现

#### 2. 科技巨头动态
[详细解读]

### 💡 知识拓展
[背景知识、技术解释]

### 📈 数据看板
[今日市场数据可视化]

### 🔗 推荐阅读
[基于用户兴趣的深度链接]
```

---

## 二、新闻重要性评分系统

### 2.1 评分维度 (总分100)

```javascript
const importanceScoring = {
  // 1. 影响范围 (0-30分)
  impactScope: {
    global: 30,      // 全球影响
    national: 20,    // 全国影响
    industry: 15,    // 行业影响
    niche: 5         // 小众领域
  },

  // 2. 时效性 (0-25分)
  timeliness: {
    breaking: 25,    // 突发新闻
    today: 20,       // 当日重大
    week: 10,        // 本周重要
    background: 5    // 背景信息
  },

  // 3. 相关性 (0-20分)
  relevance: {
    direct: 20,      // 直接相关(AI、科技)
    adjacent: 15,    // 相邻领域
    tangential: 10,  // 间接相关
    general: 5       // 一般资讯
  },

  // 4. 独特性 (0-15分)
  uniqueness: {
    exclusive: 15,   // 独家/首发
    significant: 10, // 重要进展
    incremental: 5,  // 渐进式更新
    routine: 2       // 常规消息
  },

  // 5. 用户兴趣匹配 (0-10分)
  userInterest: {
    // 基于用户历史行为动态计算
    high: 10,
    medium: 5,
    low: 2,
    none: 0
  }
};
```

### 2.2 LLM评分提示词

```javascript
const scoringPrompt = `
你是一个新闻价值评估专家。请对以下新闻进行评分（0-100分）。

新闻标题: ${title}
新闻内容: ${description}
相关领域: ${category}
发布时间: ${publishedAt}

请从以下维度评分并返回JSON:
{
  "impactScope": 分数 (0-30),
  "timeliness": 分数 (0-25),
  "relevance": 分数 (0-20),
  "uniqueness": 分数 (0-15),
  "userInterest": 分数 (0-10),
  "totalScore": 总分,
  "shouldPushImmediately": boolean,
  "category": "AI|科技|商业|其他",
  "keywords": ["关键词1", "关键词2"],
  "reasoning": "评分理由"
}

即时推送标准:
- 总分 >= 80分
- 或 impactScope >= 25 且 timeliness >= 20
`;
```

---

## 三、深度报告生成系统

### 3.1 报告结构设计

```typescript
interface DeepReport {
  // 基本信息
  id: string;
  type: 'breaking' | 'daily' | 'weekly' | 'special';
  title: string;
  summary: string; // 推送通知用

  // 核心内容
  sections: ReportSection[];

  // 元数据
  sources: NewsSource[];
  relatedStocks: StockData[];
  images: ReportImage[];
  charts: ChartData[];
  timeline: TimelineEvent[];

  // 推荐数据
  readingTime: number; // 分钟
  difficulty: 'beginner' | 'intermediate' | 'advanced';

  // 分析数据
  importanceScore: number;
  sentiment: 'positive' | 'neutral' | 'negative';
  topics: string[];

  created_at: Date;
}

interface ReportSection {
  id: string;
  type: 'analysis' | 'background' | 'impact' | 'outlook' | 'data';
  title: string;
  content: string; // Markdown格式
  order: number;

  // 可选元素
  subsections?: ReportSection[];
  images?: string[];
  charts?: ChartData[];
  keyPoints?: string[];
}
```

### 3.2 LLM生成提示词

```javascript
const deepReportPrompt = `
你是一位资深的科技分析师和商业记者。请基于以下新闻素材，撰写一份深度分析报告。

## 输入素材

${newsArticles.map(article => `
### ${article.title}
- 发布时间: ${article.publishedAt}
- 来源: ${article.source.name}
- 内容: ${article.description}
- 链接: ${article.url}
`).join('\n')}

## 输出要求

请生成JSON格式的深度报告，包含以下部分：

### 1. 执行摘要 (Executive Summary)
- 150-200字的精华概括
- 突出最重要信息
- 适合快速阅读

### 2. 深度分析 (Deep Analysis)
从多个角度分析：
- **行业影响**: 对整个行业的影响
- **技术层面**: 技术细节和创新点
- **商业角度**: 商业模式和市场竞争
- **社会影响**: 对用户和社会的影响

每个角度需要：
- 详细论述 (300-500字)
- 数据支撑
- 专家观点 (如果素材中有)

### 3. 背景知识 (Context)
- 相关历史
- 术语解释
- 前情提要

### 4. 影响展望 (Outlook)
- 短期影响 (1-3个月)
- 中期趋势 (3-12个月)
- 长期意义 (1-3年)

### 5. 数据看板 (Data)
- 相关股票表现
- 市场数据
- 统计图表 (用Mermaid语法)

### 6. 关键要点 (Key Takeaways)
- 5-7个要点列表
- 每个要点1句话
- 便于记忆

### 7. 延伸阅读 (Further Reading)
- 推荐相关链接
- 分组呈现

## 写作风格
- 专业但不晦涩
- 数据驱动
- 客观平衡
- 适合受过良好教育的读者
- 使用中文表情符号增加可读性

## 输出格式
返回JSON:
{
  "title": "报告标题",
  "summary": "150字摘要",
  "sections": [
    {
      "type": "analysis",
      "title": "章节标题",
      "content": "Markdown内容",
      "keyPoints": ["要点1", "要点2"],
      "order": 1
    }
  ],
  "charts": [
    {
      "type": "timeline|pie|line",
      "title": "图表标题",
      "data": "Mermaid或数据",
      "order": 1
    }
  ],
  "readingTime": 8,
  "difficulty": "intermediate",
  "topics": ["AI", "OpenAI", "LLM"],
  "sentiment": "positive"
}
`;
```

### 3.3 报告模板

```javascript
// 专题报告模板
const SPECIAL_REPORT_TEMPLATES = {
  'AI_BENCHMARK': {
    title: 'AI大模型评测报告',
    sections: ['技术对比', '性能测试', '应用场景', '成本分析'],
    chartTypes: ['radar', 'bar', 'line']
  },
  'TECH_M&A': {
    title: '科技公司并购分析',
    sections: ['交易详情', '战略意图', '市场反应', '整合挑战'],
    chartTypes: ['timeline', 'pie', 'organization']
  },
  'PRODUCT_LAUNCH': {
    title: '新产品发布深度解读',
    sections: ['产品特性', '竞争优势', '市场定位', '用户影响'],
    chartTypes: ['comparison', 'roadmap']
  }
};
```

---

## 四、推荐引擎设计

### 4.1 推荐算法

```javascript
class RecommendationEngine {
  // 混合推荐策略
  async getRecommendations(userId, limit = 10) {
    const recommendations = [];

    // 1. 协同过滤 (40%权重)
    const collaborative = await this.collaborativeFiltering(userId);
    recommendations.push(...collaborative);

    // 2. 内容匹配 (30%权重)
    const contentBased = await this.contentBasedFiltering(userId);
    recommendations.push(...contentBased);

    // 3. 热门趋势 (20%权重)
    const trending = await this.getTrendingTopics();
    recommendations.push(...trending);

    // 4. 探索性推荐 (10%权重)
    const exploration = await this.exploration(userId);
    recommendations.push(...exploration);

    // 去重和排序
    return this.rankAndDeduplicate(recommendations, limit);
  }

  // 协同过滤: 找相似用户
  async collaborativeFiltering(userId) {
    // 1. 计算用户相似度 (余弦相似度)
    const similarUsers = await this.findSimilarUsers(userId, topK: 20);

    // 2. 获取相似用户喜欢的内容
    const theirInterests = await this.getUserInterests(similarUsers);

    // 3. 过滤掉当前用户已读的
    return theirInterests.filter(item => !this.hasRead(userId, item.id));
  }

  // 基于内容: 匹配用户兴趣标签
  async contentBasedFiltering(userId) {
    const userProfile = await this.getUserProfile(userId);

    // 用户兴趣向量: {AI: 0.8, 股票: 0.6, ...}
    const interests = userProfile.interests;

    // 查找匹配的新闻
    const messages = await Message.findAll({
      where: {
        topics: { [Op.overlap]: Object.keys(interests) }
      },
      order: [['created_at', 'DESC']],
      limit: 50
    });

    // 计算匹配分数
    return messages.map(msg => ({
      ...msg,
      matchScore: this.calculateMatchScore(msg, interests)
    })).sort((a, b) => b.matchScore - a.matchScore);
  }

  // 热门趋势
  async getTrendingTopics() {
    // 过去24小时:
    // - 阅读数最多
    // - 转发最多
    // - 评分最高
    return await Message.findAll({
      where: {
        created_at: { [Op.gte]: moment().subtract(24, 'hours') }
      },
      order: [
        ['viewCount', 'DESC'],
        ['importanceScore', 'DESC']
      ],
      limit: 10
    });
  }

  // 探索性: 推荐新领域
  async exploration(userId) {
    const userProfile = await this.getUserProfile(userId);
    const currentInterests = Object.keys(userProfile.interests);

    // 找相关但用户未涉足的领域
    const relatedTopics = await this.findRelatedTopics(currentInterests);

    // 推荐这些领域的高分内容
    return await Message.findAll({
      where: {
        topics: { [Op.overlap]: relatedTopics },
        importanceScore: { [Op.gte]: 70 }
      },
      limit: 5
    });
  }
}
```

### 4.2 用户兴趣建模

```javascript
// 用户画像数据结构
{
  userId: UUID,
  interests: {
    // 主题兴趣度 (0-1)
    "AI": 0.9,
    "苹果": 0.7,
    "股票": 0.6,
    "新能源": 0.4,
    ...
  },

  // 阅读偏好
  preferences: {
    contentLength: "medium", // short/medium/long
    difficulty: "intermediate",
    topics: ["AI", "科技", "商业"],
    timeOfDay: "evening" // 偏好阅读时间
  },

  // 行为统计
  behavior: {
    totalRead: 156,
    avgReadingTime: 5.2, // 分钟
    completionRate: 0.78, // 完读率
    favoriteTopics: ["AI", "OpenAI"],
    ignoredTopics: ["游戏"]
  },

  // 协同过滤向量
  vector: [0.23, 0.45, 0.67, ...], // 100维向量

  updated_at: Timestamp
}
```

### 4.3 兴趣更新策略

```javascript
// 实时更新用户兴趣
async function updateUserInterests(userId, messageId, action) {
  const message = await Message.findByPk(messageId);

  // 阅读行为权重
  const weights = {
    'view': 1,        // 浏览
    'open': 2,        // 打开详情
    'complete': 5,    // 完整阅读
    'share': 10,      // 分享
    'favorite': 20    // 收藏
  };

  const weight = weights[action] || 1;

  // 更新主题兴趣度
  for (const topic of message.topics) {
    await UserInterest.upsert({
      userId,
      topic,
      score: sequelize.literal(`score + ${weight * 0.01}`), // 渐进增长
      lastUpdatedAt: new Date()
    });
  }

  // 更新用户向量
  await recomputeUserVector(userId);
}
```

---

## 五、性能优化方案

### 5.1 缓存策略

```javascript
// Redis缓存层级
const CACHE_STRATEGY = {
  // L1: 热点数据 (1分钟)
  hot: {
    ttl: 60,
    keys: [
      'breaking:news',           // 最新突发新闻
      'trending:topics',         // 热门话题
      'user:profile:${userId}'   // 用户画像
    ]
  },

  // L2: 温数据 (1小时)
  warm: {
    ttl: 3600,
    keys: [
      'messages:list:${page}',   // 消息列表
      'recommend:${userId}',     // 推荐结果
      'digest:daily:${date}'     // 每日摘要
    ]
  },

  // L3: 冷数据 (24小时)
  cold: {
    ttl: 86400,
    keys: [
      'news:history:${date}',    // 历史新闻
      'stats:views:${date}'      // 统计数据
    ]
  }
};

// 缓存预热
async function cacheWarmup() {
  // 每天凌晨3点预热
  const tomorrow = moment().add(1, 'day').format('YYYY-MM-DD');

  // 预生成每日摘要
  const dailyDigest = await generateDailyDigest();

  // 缓存推荐结果
  const activeUsers = await getActiveUsers();
  for (const user of activeUsers) {
    const recs = await recommendationEngine.getRecommendations(user.id);
    await redis.setex(`recommend:${user.id}`, 3600, JSON.stringify(recs));
  }
}
```

### 5.2 数据库优化

```sql
-- 1. 分区表 (按月)
CREATE TABLE messages (
  id UUID,
  message_type VARCHAR(50),
  title TEXT,
  -- ... 其他字段
  created_at TIMESTAMP
) PARTITION BY RANGE (created_at);

-- 创建分区
CREATE TABLE messages_2025_01 PARTITION OF messages
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE messages_2025_02 PARTITION OF messages
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- 2. 全文搜索索引
CREATE INDEX idx_messages_fts ON messages
USING gin(
  to_tsvector('chinese',
    coalesce(title, '') || ' ' ||
    coalesce(content_rich, '') || ' ' ||
    coalesce(summary, '')
  )
);

-- 3. 部分索引 (只索引未读消息)
CREATE INDEX idx_unread_messages
ON messages (created_at DESC)
WHERE is_read = false;

-- 4. 覆盖索引 (包含常用字段)
CREATE INDEX idx_messages_covering
ON messages (user_id, created_at, id, title, summary);

-- 5. 物化视图 (热门内容)
CREATE MATERIALIZED VIEW mv_hot_messages AS
SELECT
  m.id,
  m.title,
  m.summary,
  m.importance_score,
  COUNT(DISTINCT ma.user_id) as reader_count,
  AVG(ma.reading_time) as avg_reading_time
FROM messages m
LEFT JOIN message_analytics ma ON ma.message_id = m.id
WHERE m.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY m.id
HAVING COUNT(DISTINCT ma.user_id) >= 10
ORDER BY reader_count DESC;

-- 定期刷新
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mv_hot_messages
ON mv_hot_messages (reader_count DESC);

-- cron job: 每小时刷新
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hot_messages;
```

### 5.3 消息队列

```javascript
// 使用Bull处理异步任务
import Queue from 'bull';

// 1. 新闻评估队列 (高优先级)
const newsEvaluationQueue = new Queue('news-evaluation', {
  redis: { port: 6379, host: 'localhost' },
  defaultJobOptions: {
    priority: 1,
    attempts: 3,
    backoff: 'exponential',
    timeout: 30000 // 30秒超时
  }
});

newsEvaluationQueue.process(async (job) => {
  const { newsArticle } = job.data;

  // 评估重要性
  const score = await evaluateImportance(newsArticle);

  if (score.totalScore >= 80) {
    // 立即推送到高优先级队列
    await breakingNewsQueue.add({
      news: newsArticle,
      score
    }, { priority: 1 });
  }

  return score;
});

// 2. 突发新闻推送队列 (最高优先级)
const breakingNewsQueue = new Queue('breaking-news', {
  redis: { port: 6379, host: 'localhost' }
});

breakingNewsQueue.process(async (job) => {
  const { news, score } = job.data;

  // 生成快速摘要
  const summary = await generateQuickSummary(news);

  // 生成深度报告
  const report = await generateDeepReport([news]);

  // 推送给所有设备
  await pushToAllDevices({
    type: 'breaking',
    title: news.title,
    body: summary,
    data: { messageId: report.id }
  });

  return { pushed: true };
});

// 3. 每日摘要队列 (定时任务)
const digestQueue = new Queue('daily-digest', {
  redis: { port: 6379, host: 'localhost' }
});

digestQueue.process(async (job) => {
  const { date } = job.data;

  // 生成深度报告
  const digest = await generateComprehensiveDigest(date);

  // 推送给所有用户
  const users = await getActiveUsers();

  for (const user of users) {
    // 根据用户偏好个性化
    const personalized = await personalizeDigest(user, digest);

    await pushToDevice(user.deviceToken, {
      type: 'daily',
      title: personalized.title,
      body: personalized.summary
    });
  }

  return { sent: users.length };
});
```

### 5.4 CDN和静态资源

```javascript
// 图片优化和CDN
const imageOptimizer = {
  // 缩略图
  thumbnail: (url) => {
    return `${CDN_URL}/image/thumbnail/${hash(url)}.webp`;
  },

  // 中等尺寸
  medium: (url) => {
    return `${CDN_URL}/image/medium/${hash(url)}.webp`;
  },

  // 原图
  original: (url) => {
    return `${CDN_URL}/image/original/${hash(url)}.webp`;
  }
};

// 消息内容包含的图片自动处理
async function processImages(content) {
  const images = extractImageUrls(content);

  return await Promise.all(images.map(async (url) => {
    // 下载并优化
    const optimized = await downloadAndOptimize(url);

    // 上传到CDN
    const cdnUrl = await uploadToCDN(optimized);

    return {
      original: url,
      thumbnail: imageOptimizer.thumbnail(cdnUrl),
      medium: imageOptimizer.medium(cdnUrl),
      original: imageOptimizer.original(cdnUrl)
    };
  }));
}
```

### 5.5 推送优化

```javascript
// 批量推送 + 优先级
async function optimizedPush(message, devices) {
  // 1. 按用户分组
  const grouped = groupDevicesByUser(devices);

  // 2. 每个用户只推送到活跃设备
  const activeDevices = await getActiveDevicesPerUser(grouped);

  // 3. 批量发送 (并发20)
  const batches = chunk(activeDevices, 20);

  for (const batch of batches) {
    await Promise.allSettled(
      batch.map(device => aps.send(device.token, message))
    );
  }
}

// 推送优先级策略
const PUSH_PRIORITIES = {
  breaking: {
    priority: 10,
    throttle: 0, // 不限流
    sound: 'default',
    badge: true
  },
  daily: {
    priority: 5,
    throttle: 100, // 每秒最多100个
    sound: 'default',
    badge: true
  },
  marketing: {
    priority: 1,
    throttle: 10,
    sound: undefined, // 静默
    badge: false
  }
};
```

---

## 六、数据库Schema更新

```sql
-- 1. 消息表增强
ALTER TABLE messages ADD COLUMN importance_score INTEGER DEFAULT 0;
ALTER TABLE messages ADD COLUMN is_breaking BOOLEAN DEFAULT false;
ALTER TABLE messages ADD COLUMN difficulty VARCHAR(20) DEFAULT 'intermediate';
ALTER TABLE messages ADD COLUMN reading_time INTEGER; -- 预估阅读时间(分钟)
ALTER TABLE messages ADD COLUMN topics JSONB DEFAULT '[]'::jsonb;
ALTER TABLE messages ADD COLUMN sentiment VARCHAR(20);
ALTER TABLE messages ADD COLUMN sections JSONB DEFAULT '[]'::jsonb; -- 深度报告章节

-- 索引
CREATE INDEX idx_messages_importance ON messages(importance_score DESC, created_at DESC);
CREATE INDEX idx_messages_breaking ON messages(is_breaking, created_at DESC) WHERE is_breaking = true;
CREATE INDEX idx_messages_topics ON messages USING gin(topics);

-- 2. 用户兴趣表
CREATE TABLE user_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    score FLOAT DEFAULT 0,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, topic)
);

CREATE INDEX idx_user_interests_score ON user_interests(user_id, score DESC);

-- 3. 用户行为表
CREATE TABLE user_behaviors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- view, open, complete, share, favorite
    reading_time INTEGER, -- 阅读时长(秒)
    device_info JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 分区表 (按月)
CREATE TABLE user_behaviors (
    -- 同上结构
) PARTITION BY RANGE (created_at);

-- 4. 推荐缓存表
CREATE TABLE recommendation_cache (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    recommendations JSONB NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_rec_cache_expires ON recommendation_cache(expires_at);

-- 5. 突发新闻追踪
CREATE TABLE breaking_news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id),
    original_url TEXT UNIQUE,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pushed_at TIMESTAMP,
    score INTEGER NOT NULL
);

-- 6. 深度报告元数据
CREATE TABLE deep_reports (
    id UUID PRIMARY KEY,
    message_id UUID REFERENCES messages(id),
    report_type VARCHAR(50), -- breaking, daily, weekly, special
    word_count INTEGER,
    section_count INTEGER,
    chart_count INTEGER,
    image_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 七、API端点设计

### 7.1 新增端点

```javascript
// 突发新闻检查
GET /api/admin/breaking-news/check
POST /api/admin/breaking-news/trigger

// 深度报告
GET /api/reports?type=daily&date=2025-01-17
GET /api/reports/:id
GET /api/reports/trending

// 推荐系统
GET /api/recommendations?userId=xxx&limit=10
POST /api/recommendations/feedback
  { messageId, action: 'like'|'dislike'|'hide' }

// 用户兴趣
GET /api/users/:userId/interests
PUT /api/users/:userId/interests
  { topics: {AI: 0.8, 股票: 0.6} }

// 搜索增强
GET /api/search?q=AI&type=all&filters={dateRange,topics,minScore}

// 统计分析
GET /api/analytics/messages/:id
  { views, avgReadingTime, completionRate, shareCount }
```

### 7.2 现有端点增强

```javascript
// GET /api/messages
查询参数增强:
- ?type=breaking (突发新闻)
- ?minScore=80 (最低重要性)
- ?topics=AI,股票 (主题筛选)
- ?difficulty=intermediate (难度级别)
- ?sort=importance|recent|popular

// POST /api/devices/register
请求体增强:
{
  deviceToken: "xxx",
  preferences: {
    topics: ["AI", "科技"],
    difficulty: "intermediate",
    quietHours: { start: "22:00", end: "08:00" },
    breakingNews: true,
    dailyDigest: true
  }
}
```

---

## 八、iOS客户端更新

### 8.1 新增功能

```swift
// 1. 突发新闻Banner
struct BreakingNewsBanner: View {
    @StateObject private var viewModel = BreakingNewsViewModel()

    var body: some View {
        if let breaking = viewModel.latestBreaking {
            HStack {
                PulseAnimation()
                Text(breaking.title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .onTapGesture {
                // 跳转到详情
            }
        }
    }
}

// 2. 深度报告阅读器
struct DeepReportReader: View {
    let report: DeepReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和元数据
                ReportHeader(report: report)

                // 章节导航
                ChapterNavigation(chapters: report.sections)

                // 内容区域
                ForEach(report.sections) { section in
                    ReportSectionView(section: section)
                }

                // 相关推荐
                RelatedReports(reportId: report.id)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 3. 推荐页面
struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.recommendations) { item in
                    RecommendationCard(item: item)
                }
            }
        }
        .navigationTitle("为你推荐")
    }
}

// 4. 主题管理
struct TopicManagerView: View {
    @StateObject private var viewModel = TopicManagerViewModel()

    var body: some View {
        List {
            ForEach(viewModel.topics) { topic in
                HStack {
                    Text(topic.name)
                    Spacer()
                    Slider(value: $topic.interest, in: 0...1)
                    Text("\(Int(topic.interest * 100))%")
                }
            }
        }
        .navigationTitle("兴趣管理")
    }
}
```

### 8.2 深度报告渲染

```swift
// Markdown渲染 + 图表支持
import MarkdownUI
import Charts

struct ReportSectionView: View {
    let section: ReportSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 章节标题
            Text(section.title)
                .font(.title2)
                .fontWeight(.bold)

            // Markdown内容
            MarkdownUI(section.content)
                .markdownTheme(.gitHub)

            // 关键要点
            if let keyPoints = section.keyPoints {
                ForEach(keyPoints, id: \.self) { point in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text(point)
                        Spacer()
                    }
                }
            }

            // 图表
            if let charts = section.charts {
                ForEach(charts) { chart in
                    ChartView(chart: chart)
                }
            }
        }
    }
}
```

---

## 九、监控和分析

### 9.1 关键指标

```javascript
// 性能指标
const PERFORMANCE_METRICS = {
  // 推送延迟
  pushLatency: {
    breaking: 'p50<5s, p95<30s',
    daily: 'p50<30s, p95<2min'
  },

  // API响应时间
  apiLatency: {
    search: 'p50<200ms, p95<500ms',
    recommendations: 'p50<300ms, p95<1s',
    messages: 'p50<100ms, p95<300ms'
  },

  // LLM调用
  llmLatency: {
    importance: 'p50<3s, p95<10s',
    report: 'p50<15s, p95<30s'
  }
};

// 业务指标
const BUSINESS_METRICS = {
  // 用户参与度
  dailyActiveUsers: 'DAU',
  averageReadingTime: '分钟/天',
  completionRate: '完读率',

  // 推送效果
  pushOpenRate: '打开率',
  pushClickRate: '点击率',

  // 推荐效果
  recommendationCTR: '推荐点击率',
  recommendationSatisfaction: '满意度'
};
```

---

## 十、实施计划

### Phase 1: 双通道推送 (Week 1-2)
- [ ] 新闻重要性评分系统
- [ ] 突发新闻即时推送
- [ ] 定时摘要生成优化
- [ ] 推送优先级管理

### Phase 2: 深度报告 (Week 3-4)
- [ ] LLM提示词优化
- [ ] 报告结构设计
- [ ] 图表和数据可视化
- [ ] iOS报告阅读器

### Phase 3: 推荐系统 (Week 5-6)
- [ ] 用户兴趣建模
- [ ] 协同过滤算法
- [ ] 混合推荐策略
- [ ] 推荐结果缓存

### Phase 4: 性能优化 (Week 7-8)
- [ ] Redis多层缓存
- [ ] 数据库分区和索引
- [ ] 消息队列异步处理
- [ ] CDN图片优化

### Phase 5: 监控和分析 (Week 9-10)
- [ ] 性能监控仪表板
- [ ] 用户行为分析
- [ ] A/B测试框架
- [ ] 持续优化迭代
