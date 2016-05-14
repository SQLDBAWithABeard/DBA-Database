CREATE TABLE [dbo].[InstanceScriptLookup]
(
[ISLID] [int] NOT NULL IDENTITY(1, 1),
[InstanceID] [int] NOT NULL,
[ScriptID] [int] NOT NULL,
[NeedsUpdate] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InstanceScriptLookup] ADD CONSTRAINT [PK_InstanceScriptLookup] PRIMARY KEY CLUSTERED  ([ISLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InstanceScriptLookup] ADD CONSTRAINT [FK_InstanceScriptLookup_InstanceList] FOREIGN KEY ([InstanceID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
ALTER TABLE [dbo].[InstanceScriptLookup] ADD CONSTRAINT [FK_InstanceScriptLookup_ScriptList] FOREIGN KEY ([ScriptID]) REFERENCES [dbo].[ScriptList] ([ScriptID])
GO
