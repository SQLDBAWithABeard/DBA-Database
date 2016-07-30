CREATE TABLE [dbo].[InstanceList]
(
[InstanceID] [int] NOT NULL IDENTITY(1, 1),
[ServerName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[InstanceName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[Port] [int] NOT NULL,
[Inactive] [bit] NULL CONSTRAINT [DF_InstanceList_Inactive] DEFAULT ((0)),
[Environment] [nvarchar] (25) COLLATE Latin1_General_CI_AS NULL,
[Location] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[NotContactable] [bit] NULL CONSTRAINT [DF_InstanceList_NotContactable] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InstanceList] ADD CONSTRAINT [PK_InstanceList_ID] PRIMARY KEY CLUSTERED  ([InstanceID]) ON [PRIMARY]
GO
