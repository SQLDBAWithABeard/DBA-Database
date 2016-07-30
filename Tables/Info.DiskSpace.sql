CREATE TABLE [Info].[DiskSpace]
(
[DiskSpaceID] [int] NOT NULL IDENTITY(1, 1),
[Date] [date] NOT NULL,
[ServerID] [int] NOT NULL,
[DiskName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Label] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Capacity] [decimal] (7, 2) NULL,
[FreeSpace] [decimal] (7, 2) NULL,
[Percentage] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[DiskSpace] ADD CONSTRAINT [PK_DiskSpace_1] PRIMARY KEY CLUSTERED  ([DiskSpaceID]) ON [PRIMARY]
GO
ALTER TABLE [Info].[DiskSpace] ADD CONSTRAINT [FK_DiskSpace_InstanceList] FOREIGN KEY ([ServerID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
