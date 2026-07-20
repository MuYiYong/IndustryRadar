# FinTech Risk Control

## 2026-07-20｜W29 知识追加

### 金融 Agent 治理升级

金融 AI 的要求正在从模型“可解释”升级为完整行动链的“可追责、可干预、可恢复”。治理对象需要覆盖用户意图、Agent 计划、数据读取、模型判断、工具调用、业务状态变化以及对客户和市场的影响。

### 关键控制能力

- 每个 Agent 使用独立身份，避免共享万能账号；
- 根据任务实行最小权限和动态授权；
- 将查询、建议、提交、审批和执行划分为不同风险等级；
- 对资金、授信、交易和客户权益相关动作保留人工审批；
- 记录输入、数据版本、模型、规则、工具和最终动作；
- 提供 kill switch、撤销和补偿机制；
- 监控多个 Agent 是否出现异常同步或风险共振。

### 图与本体机会

本体用于定义监管口径、业务对象、风险类型和控制规则；图数据库用于表达客户、账户、交易、模型、Agent、工具与规则之间的关系，并进行权限传播、风险传播、集中度和影响范围分析。

参考：[AWS：Preparing for agentic AI in financial services](https://aws.amazon.com/blogs/security/preparing-for-agentic-ai-a-financial-services-approach/)
