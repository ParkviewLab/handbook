# An agent team

Part of the `dispatch` skill; read when this structure is chosen.

Enable teams for that session or repo only, never in user settings: a `.claude/settings.json` in the repo worktree with `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}`, or `--settings '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}'` on the command line. While enabled, every subagent spawned with a name launches as a teammate.

Run the team as the documentation prescribes: break the work into tasks on the shared task list (five or six per teammate), spawn three to five teammates by the Agent tool with a `name` each, give each its full context in its spawn prompt (no history carries over), assign disjoint files, use the agent definitions as teammate roles, wait for the teammates rather than doing their work, and monitor and steer. Teammates run in the lead's directory, take the model the spawning call names (their definition's where it names none) and the lead's effort, end with the lead's session, cannot be resumed, and cannot spawn background subagents; permission prompts go to the lead. Remove the setting when the team's work is done.
