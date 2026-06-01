# Claude Code 使用说明

本仓库里的 `de-AI-writing` 和 `good-writing` 已按轻量读取方式整理。Claude Code 调用时应优先读取各 Skill 的 `SKILL.md`，再按入口文件中的“读取策略”加载短索引或摘要。

## 安装位置确认

如果 Claude Code 实际读取的是全局技能目录，需要确认以下位置是否和本仓库同步：

- 仓库版本：`E:\_BIGFAFree\_code\De-AI-Prompt-Enhancer-Writer-Booster-SKILL\de-AI-writing`
- 仓库版本：`E:\_BIGFAFree\_code\De-AI-Prompt-Enhancer-Writer-Booster-SKILL\good-writing`
- 可能的全局版本：`E:\_BIGFAFree\_code\skills\de-AI-writing`
- 可能的全局版本：`E:\_BIGFAFree\_code\skills\good-writing`

当前仓库只负责维护仓库内两份 Skill。若 Claude Code 仍卡在 Read，请先确认它加载的不是旧的全局副本。

## 读取约束

- 不要启动时通读 `ai-trace-detector.md`。
- 不要启动时通读 `writing-samples.md`。
- `good-writing` 默认先读 `references/style-summary.md`。
- AI 痕迹检查默认先读 `references/ai-trace-index.md`。
- 只有命中具体问题时，才读取详细参考文件的相关章节。

## 快速排查

如果仍然卡顿，优先检查：

1. Claude Code 实际加载的 Skill 路径。
2. 是否有旧版 `SKILL.md` 仍要求“必先通读完整范文”。
3. 是否有提示词要求直接打开完整 `ai-trace-detector.md`。
4. 是否有外部配置把整个 Skill 目录一次性读入。
