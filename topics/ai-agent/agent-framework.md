# Agent Framework

## 2026-07-20｜W29 知识追加

### Agent Control Plane

企业 Agent 数量增长后，治理对象将从单个 Agent 扩展为跨部门、跨系统的 Agent 网络。生产级控制平面至少需要统一管理身份与委托、上下文与本体、工具与连接器、动态策略、任务状态、补偿回滚和证据链。

### Bounded Autonomy

企业级 Agent 的成熟度不应以减少人工确认的数量衡量，而应以其能否在明确授权边界内实现可验证、可审计、可恢复的自主执行衡量。

### Agent Sprawl

常见风险包括重复建设、凭证扩散、共享系统冲突操作、跨监管边界、隐藏成本，以及多个 Agent 通过局部合法动作形成全局违规。图模型适合表达 Agent、用户、业务单元、工具、数据、规则、任务和影响对象之间的运行关系。

### 建议架构

> 用户意图 → 计划生成 → 上下文装配 → 权限与规则检查 → Dry Run → 工具执行 → 运行监控 → 证据归档 → 回滚或补偿

参考：[AWS：Managing AI agent sprawl across business units](https://aws.amazon.com/blogs/industries/managing-ai-agent-sprawl-across-business-units/)、[Alation：Introducing AIOS](https://www.alation.com/blog/introducing-aios-alation-intelligence-operating-system/)
