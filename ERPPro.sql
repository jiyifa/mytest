USE KpowerERP
GO
	If Exists ( Select name From sysobjects Where name = 'sp_CommQueryProc' and type='P')
		Drop Procedure [storage].[sp_CommQueryProc]
GO
/*

���ܣ�
	ִ��SQL����ѯ��ҳ�Ĺ����洢���̡�

������
	@pSQL	varchar(8000)	SQL���
	@pIDCol	varchar(50)		ID����
	@pCurPage	int = 1		��ǰҳ
	@pPageSize	int = 20	ҳ��С

���أ�
	�������������ID�������ID�ö��ŷָ�
*/
CREATE PROCEDURE [storage].[sp_CommQueryProc]
(
	@pSQL varchar(8000),	--SQL���
	@pIDCol varchar(50),	--ID����
	@pOrder varchar(500)='',	--�����ִ�
	@pCurPage int = 1,	--��ǰҳ
	@pPageSize int = 20,	--ҳ��С
	@pRecNums int output,	--��¼��
	@pRecPages int output	--��¼ҳ��
	
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(5000)
	declare @strSubSQL varchar(5000)
	declare @RecStart int
	declare @RecEnd  int
	declare @MaxCount int
	declare @Pages int
	set @MaxCount = 0
	set @Pages = 0

	--���뵱ǰҳ����ǰ�����ݵ�IDֵ����ʱ��
	create table #tmpTable(
		[ID]		numeric identity(1,1) not null,
		[DataID]	numeric not null
	)

	--set @strSubSQL = 'SELECT top ' + convert(varchar(100),@PageEnd) + ' ' + @pIDCol
	set @strSubSQL = 'SELECT ' + @pIDCol
			 + '  FROM (' + @pSQL + ') '
	set @strSQL = 'INSERT INTO #tmpTable([DataID]) ' + @strSubSQL + ' as st '
	if(@pOrder != '')
		set @strSQL = @strSQL + ' order by ' + @pOrder

	exec(@strSQL)
	set @MaxCount = @@rowcount
	if @@ERROR != 0 goto Err_Proc

	set @Pages = @MaxCount/@pPageSize
	if(@MaxCount % @pPageSize > 0)
		set @Pages = @Pages + 1

	if(@pCurPage<=0)
		set @pCurPage = 1
	if(@pCurPage > @Pages)
		set @pCurPage = @Pages			--����ĵ�ǰҳ�Ŵ�����ҳ������������⴦��

	set @RecStart = (@pCurPage-1) * @pPageSize + 1	--������ʾ��ʵ����
	set @RecEnd = @pCurPage * @pPageSize		--������ʾ��ֹ����

	set @pRecNums = @MaxCount		--��¼��
	set @pRecPages = @Pages		--��¼ҳ��

	--����ʱ���е��������Ӽ��е�����ƥ��
	set @strSQL = 'SELECT st.* FROM (' + @pSQL + ') as st,#tmpTable tt 
			WHERE tt.[ID] >=' + convert(varchar(100),@RecStart) + ' 
				AND tt.[ID] <= ' + convert(varchar(100),@RecEnd) + ' 
				AND tt.[DataID] = st.' + @pIDCol
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc
OK_Proc:
	commit tran
	drop table #tmpTable
	set nocount off
	return 0
Err_Proc:
	rollback tran
	print @strSQL
	drop table #tmpTable
	set nocount off
	return -1
END
GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddQCRecord' and type='P')
		Drop Procedure [storage].[sp_AddQCRecord]
GO
/*
���ܣ�
	���������Ʒ�ʼ챨��

������
	@proNO	��Ʒ���

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddQCRecord]
	@sID        varchar(50), --sID����
	@RecordID  int
AS
	EXEC ('insert into tProductQCRecDetail(RecordID,QCStandard,QCProject) 
	select RecordID='+@RecordID+',CheckStandard,CheckProject from tQuantityCheckstandard
	where ProjectID in ('+@sID+')')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddProductInstall' and type='P')
		Drop Procedure [storage].[sp_AddProductInstall]
GO
/*
���ܣ�
	���������Ʒԭ�����õ�

������
	@sID        sID����
	@productID  ��ƷID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddProductInstall]
	@sID        varchar(50), --sID����
	@InsID      int
AS
	EXEC ('insert into tProductInstallDetail(InsID,productID,sourceNo,sourceName,Model,spec,unit,number,GoodsType) 
	select InsID='+@InsID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,0,GoodsType from tGoods
	where GoodsID in ('+@sID+')')  --ʹ�ü��ϱ�����EXECִ��SQL��䣬�ڴ�ֻ����sID����������ʹ��productID����Ϊ�����ֶ�

GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddCrafRoute' and type='P')
		Drop Procedure [storage].[sp_AddCrafRoute]
GO
/*

���ܣ�
	��ӹ���·����ϸ

������
	@sID        sID����
	@productID  ��ƷID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddCrafRoute]
	@sID     varchar(50), --��������ID����    
	@crafID  int
	
AS    
    EXEC ('insert into tCrafRouteDetail(CrafID,WorkNo,WorkName,ProductFee,EqID,EqName,Status,LinupTime,PreparTime,WaitTime,ProcessTime,Conveyancetime,KeyWork) 
	select CrafID='+@crafID+',WorkNo,WorkName,0,EqID,EqName,Status,LineupTime,PreparTime,WaitTime,ProcessTime,Conveyancetime,Keywork from tWorkpreface
	where WorkID in('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddMainPlanDetail' and type='P')
		Drop Procedure [storage].[sp_AddMainPlanDetail]
GO
/*

���ܣ�
	����������ƻ�����ϸ

������
	@sID        sID����
	@SheetID    �������ƻ���ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddMainPlanDetail]
	@sID      varchar(50), --ID����    
	@SheetID  int          --�������ƻ���ID
	
AS    
	EXEC ('insert into tProductMainPlanDetail(SheetID,GoodsID,GoodsCode,GoodsName,Model,Spec,Unit,Price,pNumber,fNumber) 
		select SheetID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,Price,Nums,0 from tGoods
		where GoodsID in ('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddPlanDetail' and type='P')
		Drop Procedure [storage].[sp_AddPlanDetail]
GO
/*
���ܣ�
	�������������ϸ

������
	@sID        sID����
	@SheetID    ��������ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddPlanDetail]
	@sID      varchar(50), --ID����    
	@SheetID  int          --��������ID
	
AS    
	EXEC ('insert into tProductPlanDetail(SheetID,ProID,ProductNo,ProductName,Model,Spec,Unit,Number,Price) 
		select SheetID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,Nums,Price from tGoods
		where GoodsID in ('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_CreatePdSendWorker' and type='P')
		Drop Procedure [storage].[sp_CreatePdSendWorker]
GO
/*
���ܣ�
	�������ƻ��������ɹ���

������
	@SheetNo     --�ɹ������
	@PlanID      --�ƻ���ID
	@DetailID    --�ƻ�����ϸID����

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_CreatePdSendWorker]
	@SheetNo     varchar(50),  --�ɹ������
	@PlanID      int,          --�ƻ���ID
	@DetailID    varchar(50)   --�ƻ�����ϸID����
AS    
	declare @ID int
	insert into tSendWorker(SheetNo,PlanID,DeptID,StartTime,FinishTime,PNO) 
		select @SheetNo,SheetID,DeptID,StartWorkTime,FinishWorkTime,PNO from tProductPlan 
		where SheetID = @PlanID
	set @ID = @@IDENTITY
	EXEC('insert into tSendWorkerDetail(SheetID,ProductID,ProductNo,ProductName,Model,Spec,Unit,Price,Number,PNO,Moneys,CustID)
		select '+@ID+',ProID,ProductNo,ProductName,Model,Spec,Unit,Price,Number,PNO,Moneys,CustID from tProductPlanDetail
		where DetailID in ('+@DetailID+')')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_BuyApplyDetail' and type='P')
		Drop Procedure [storage].[sp_BuyApplyDetail]
GO
/*

���ܣ�
	��Ӳɹ����뵥

������
	@sID         --����ID����
	@SheetID     --���뵥ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_BuyApplyDetail]
	@sID        varchar(50),
	@SheetID    int
AS
	EXEC('insert into tBuyApplyDetail(SheetID,GoodsNo,Goodsname,Model,Spec,UnitName,Price,CurStoreNums,Number) 
		select SheetID='+@SheetID+',GoodsCode,GoodsName,Model,Spec,UnitName,Price,CurStoreNums,0 from tGoods
		where GoodsID in ('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddSendWorker' and type='P')
		Drop Procedure [storage].[sp_AddSendWorker]
GO
/*

���ܣ�
	��������ɹ���

������
	@sID         --����ID����
	@SheetID     --�ɹ���ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddSendWorker]
	@sID        varchar(50), --sID����
	@SheetID    int
AS
	EXEC ('insert into tSendWorkerDetail(SheetID,ProductID,ProductNo,ProductName,Model,Spec,Unit,Number,Price) 
	select SheetID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,0,Price from tGoods
	where GoodsID in ('+@sID+')')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddPdCalcDetail' and type='P')
		Drop Procedure [storage].[sp_AddPdCalcDetail]
GO
/*

���ܣ�
	��ӼƼ�����ϸ

������
	@sID        sID����
	@SheetID    �Ƽ�������ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddPdCalcDetail]
	@sID      varchar(50), --Ա������ID����    
	@SheetID  int          --�Ƽ�������ID
	
AS    
    EXEC ('insert into tCalcSheetDetail(SheetID,EmpID,EmpName,pNo,ManFee,CalcDate,StartDate,CompleteDate) 
	select SheetID='+@SheetID+',A.EmpID,A.EmpName,C.pNo,0,getDate(),C.StartTime,C.FinishTime from tCompanyEmployee A
	inner join tCalcSheet B on B.SheetID='+@SheetID+'
	inner join tSendWorker C on C.SheetID=B.SendWorkID
	where EmpID in('+@sID+')')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CreateGetMaterial' and type='P')
		Drop Procedure [storage].[sp_CreateGetMaterial]
GO
/*

���ܣ�
	���ɹ����������Ϸ����������ϵ�

������
	@SheetNo     --�������ϵ���
	@MakeBillMan --�Ƶ���
	@SheetID     --�����ɹ���ID

���أ�

�����㷨��
*/
CREATE  PROCEDURE  [storage].[sp_CreateGetMaterial]
	@SheetNo     varchar(20),         --�������ϵ���
	@MakeBillMan varchar(20),         --�Ƶ���
	@SheetID     int                  --�����ɹ���ID	
AS
	declare @ID   int
	declare @SheetNoY   varchar(20)
	declare @SheetNoB   varchar(20)

	set @SheetNoY=@SheetNo+'Y'
	set @SheetNoB=@SheetNo+'B'

	declare @pNo varchar(20)
	select @pNo=pNo from tSendWorker where SheetID=@SheetID

	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,G.Price,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType  into #GetMaterial from tSendWorker as A 
	inner join tSendWorkerDetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.ProductID = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid	
	where E.GoodsType=2 and A.sheetid=@SheetID

	if((select Count(*) from  #GetMaterial)>0)
	begin
		--ԭ��
		if((select Count(*) from  #GetMaterial where GoodsType<2)>0)
		begin
			insert into tGetMaterial(BillNO,MakeBillMan,MakeBillDate,pNo,ClassID,TakeoutType,SendWorkID)
			select @SheetNoY,@MakeBillMan,getdate(),@pNo,ClassID,0,SheetID from tSendWorker where SheetID=@SheetID
			set @ID = @@IDENTITY

			insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,GoodsName,Model,Spec,Price,pNo,OutNums,UnitName,CurStoreNums,GoodsType,CustID)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Price,@pNo,Number,Unit,CurStoreNums,GoodsType,CustID from #GetMaterial where GoodsType<2
		end

		--���
		if((select Count(*) from  #GetMaterial where GoodsType=3)>0)
		begin
			insert into tGetMaterial(BillNO,MakeBillMan,MakeBillDate,pNo,ClassID,TakeoutType,SendWorkID)
			select @SheetNoB,@MakeBillMan,getdate(),@pNo,ClassID,0,SheetID from tSendWorker where SheetID=@SheetID
			set @ID = @@IDENTITY

			insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,GoodsName,Model,Spec,Price,pNo,OutNums,UnitName,CurStoreNums,GoodsType,CustID)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Price,@pNo,Number,Unit,CurStoreNums,GoodsType,CustID from #GetMaterial where GoodsType=3
		end
	end

GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddDetailOfTakeout' and type='P')
		Drop Procedure [storage].[sp_AddDetailOfTakeout]
GO
/*

���ܣ�
	����������ϵ�

������
	@sID
	@SheetID    --�������ϵ�ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_AddDetailOfTakeout]
	@sID        varchar(50),
	@SheetID    int
AS
	EXEC('insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,GoodsName,Model,Spec,Price,UnitName,CurStoreNums,GoodsType)
		select BillOfTakeoutID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,Price,UnitName,CurStoreNums,GoodsType from tGoods
		where GoodsID in ('+@sID+')')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CostOfProduct' and type='P')
		Drop Procedure [storage].[sp_CostOfProduct]
GO
/*

���ܣ�
	�����ɱ�����

������
	@pNo  --��Ʒ����

���أ�

�����㷨��
*/
CREATE  PROCEDURE [storage].[sp_CostOfProduct]
	@pNo      varchar(20)  --��Ʒ����
AS

	declare @Material1 int  --ԭ�ϳɱ�
	declare @Material2 int  --����ɱ�
	declare @Material3 int  --����ɱ�
	declare @Material  int  --�����ϳɱ�
	declare @Calc      int  --�Ƽ��ɱ�
	declare @Eq        int  --�豸����
	declare @AllCost   int  --����ë��
	declare @Sale      int  --���۽��
	declare @Cost      int  --����ë��

	--���ϳɱ�����λ���������ϳɱ�*�����˲�Ʒ������*��λ����ֵ
	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,G.Price,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType into #MaterialFee from tProductPlan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where E.GoodsType=2 and A.pNo=@pNo

	select @Material1= sum(Price*Number) from #MaterialFee where GoodsType<2
	select @Material2= sum(Price*Number) from #MaterialFee where GoodsType=3
	select @Material3= sum(Price*OutNums) from tGetMaterialDetail where BillofTakeoutID in(select BillofTakeoutID from tGetMaterial where TakeOutType=1 and pNo=@pNo)

	set @Material= IsNull(@Material1,0)+IsNull(@Material2,0)+IsNull(@Material3,0)

	--�Ƽ��ɱ�
	select @Calc= sum(ToManFee) from tCalcSheet where pNo=@pNo

	--ͳ���豸���ã���λ�������豸����*�����˲�Ʒ������*��λ����ֵ
	select C.ProductID,C.ProductNo,C.ProductName,C.ToFee,IsNull(F.Nums,1)as Nums,B.Number into #EqFee from tProductPlan as A 
	inner join tProductPlanDetail as B on A.SheetID = B.SheetID
	inner join tCrafRoute as C on B.ProID = C.ProductID
	inner join tGoods as D on D.GoodsID  = C.ProductID
	inner join tUnit as E on B.Unit = E.UnitName
	left join tUnitConversion F on F.UnitID = E.UnitID
	where E.GoodsType=2 and A.pNo=@pNo
	select @Eq = sum(ToFee*Number*Nums) from #EqFee

	--������������ͳ��
	select @Sale = sum(TotalMoney) from tProductPlan where pNo=@pNo

	set @AllCost=@Material+@Calc+@Eq
	set @Cost = @Sale -@AllCost

	--��������
	select @pNo AS pNo,IsNull(@Material1,0) AS Material1,IsNull(@Material2,0) AS Material2,IsNull(@Material3,0) AS Material3,IsNull(@Material,0) AS Material,IsNull(@Calc,0) AS Calc,IsNull(@Eq,0) AS Eq,IsNull(@AllCost,0) AS AllCost,@Sale AS Sale,IsNull(@Cost,0) AS Cost

GO
	If Exists ( Select name From sysobjects Where name = 'sp_MaterialCount' and type='P')
		Drop Procedure [storage].[sp_MaterialCount]
GO
/*

���ܣ�
	����������������

������
	@SheetID  int                  --��������ID

���أ�

�����㷨��
*/
CREATE  PROCEDURE [storage].[sp_MaterialCount]
	@SheetID  int                  --��������ID
AS
	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType into #MaterialCount from tproductplan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where E.GoodsType=2 and A.sheetid=@SheetID --E.GoodsType=G.GoodsType and 

	--�����ظ��Ļ�Ʒ
	select ProductID,SourceNo,SourceName,Model,Spec,Unit,sum(Number)as Number,CurStoreNums,GoodsType 
	from #MaterialCount group by ProductID,SourceNo,SourceName,Model,Spec,Unit,CurStoreNums,GoodsType
GO
	If Exists ( Select name From sysobjects Where name = 'sp_MaterialCountApply' and type='P')
		Drop Procedure [storage].[sp_MaterialCountApply]
GO
/*

���ܣ�
	���������������������빺��

������
	@SheetID      --��������ID
	@SheetNo      --�빺�����
	@ApplyPerson  --�빺��
	@TablePerson  --�빺���Ƶ���
	@DeptID       --�빺������
	@ApplyCount   --�����治������ϼ�¼��

���أ�

�����㷨��
*/
CREATE  PROCEDURE [storage].[sp_MaterialCountApply]
	@SheetID      int,             --��������ID
	@SheetNo      varchar(20),     --�빺�����
	@ApplyPerson  varchar(20),     --�빺��
	@TablePerson  varchar(20),     --�빺���Ƶ���
	@DeptID       varchar(20),     --�빺������
	@ApplyCount   int out          --�����治������ϼ�¼��
AS
	declare @ID   int
	declare @SequenceNum  int      --���

	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.Price,G.CurStoreNums,G.UnitID,G.Color,G.GoodsType  into #PlanMaterial from tproductplan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where E.GoodsType=2 and A.sheetid=@SheetID

	select ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,(Number-CurStoreNums) as BuyNumber,Price,CurStoreNums,UnitID,Color,GoodsType
	into #ApplyDetail from #PlanMaterial
	where Number>CurStoreNums

	select @ApplyCount=Count(*) from  #ApplyDetail
	if(@ApplyCount>0)
	begin
		--insert into tBuyApply(SheetNo,ApplyTime,BuyReason,ApplyPerson,DeptID,TablePerson,WriteTime)
		--values(@SheetNo,getdate(),'�������Ͽ�治��',@ApplyPerson,@DeptID,@TablePerson,getdate())
		--set @ID = @@IDENTITY

		--insert into tBuyApplyDetail(SheetID,GoodsID,GoodsNo,GoodsName,Model,Spec,UnitName,UseNumber,Number,CurStoreNums,Price,Moneys)
		--select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,0,0 from #ApplyDetail

		--ԭ��
		if((select Count(*) from  #ApplyDetail where GoodsType=0)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,0)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail where GoodsType=0
		end
		--���Ʒ
		if((select Count(*) from  #ApplyDetail where GoodsType=1)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,1)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail where GoodsType=1
		end
		--���
		if((select Count(*) from  #ApplyDetail where GoodsType=3)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,3)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail where GoodsType=3
		end
	end

GO
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vwDoc]') and OBJECTPROPERTY(id, N'IsView') = 1)
		drop view [dbo].[vwDoc]
GO
/*

���ܣ�
	��ѯ���ܷ�����Ϣ

������


���أ�

�����㷨��
*/
CREATE  VIEW dbo.vwDoc
AS
SELECT dbo.tDocMain.DocID, dbo.tDocMain.DocNo, dbo.tDocMain.Title, 
      dbo.tDocMain.Object, dbo.tDocMain.ObjSend, dbo.tDocMain.CSend, 
      dbo.tDocMain.Description, dbo.tDocMain.sType, dbo.tDocMain.DocUrl, 
      dbo.tDocMain.CompID, dbo.tDocMain.DeptID, dbo.tDocMain.EmpID, 
      dbo.tDocMain.SendNo, dbo.tDocMain.SendName, dbo.tDocMain.WriteTime, 
      dbo.tDocMain.SendTime, dbo.tDocRS.RevID, dbo.tDocRS.DocID AS Expr1, 
      dbo.tDocRS.CompID AS Expr2, dbo.tDocRS.DeptID AS Expr3, 
      dbo.tDocRS.EmpID AS Expr4, dbo.tDocRS.RevName, dbo.tDocRS.RevDepName, 
      dbo.tDocRS.Status, dbo.tDocRS.RevTime
FROM dbo.tDocMain INNER JOIN
      dbo.tDocRS ON dbo.tDocMain.DocID = dbo.tDocRS.DocID

GO
	If Exists ( Select name From sysobjects Where name = 'sp_DelDocMain' and type='P')
		Drop Procedure [storage].[sp_DelDocMain]
GO
/*
���ܣ�
	ɾ������

������
	@docid  ����ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_DelDocMain]
	@docid int
AS
	delete from tReInfo where DocID=@docid  --�ظ�
	delete from tDocRs where DocID=@docid   --������ϸ
	delete from tDocMain where DocID=@docid --��������
GO
	If Exists ( Select name From sysobjects Where name = 'sp_GetMaterialBuyApply' and type='P')
		Drop Procedure [storage].[sp_GetMaterialBuyApply]
GO
/*

���ܣ�
	���������ϵ����ڿ���в�������������빺��

������
	@SheetID      --�������ϵ�ID
	@SheetNo      --�빺�����
	@ApplyPerson  --�빺��
	@TablePerson  --�Ƶ���
	@BuyCount     --�빺���ϼ�¼��

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_GetMaterialBuyApply]
	@SheetID      int,           --�������ϵ�ID
	@SheetNo      varchar(20),   --�빺�����
	@ApplyPerson  varchar(20),   --�빺��
	@TablePerson  varchar(20),   --�Ƶ���
	@BuyCount     int out        --�빺���ϼ�¼��
AS
	declare @ID   int
	declare @SequenceNum  int    --���

	select GoodsID,GoodsCode,GoodsName,Model,Spec,Price,UnitName,OutNums,(OutNums-CurStoreNums) as Number,CurStoreNums,(Price*(OutNums-CurStoreNums))as Moneys,GoodsType
	into #BuyApplyDetail from tGetMaterialDetail 
	where BillOfTakeoutID = @SheetID and OutNums>CurStoreNums

	select @BuyCount=Count(*) from  #BuyApplyDetail
	if(@BuyCount>0)
	begin
		--insert into tBuyApply(SheetNo,ApplyTime,BuyReason,ApplyPerson,TablePerson,WriteTime)
		--values(@SheetNo,getdate(),'�������Ͽ�治��',@ApplyPerson,@TablePerson,getdate())
		--set @ID = @@IDENTITY

		--insert into tBuyApplyDetail(SheetID,GoodsID,GoodsNo,GoodsName,Model,Spec,Price,UnitName,UseNumber,Number,CurStoreNums,Moneys)
		--select @ID,GoodsID,GoodsCode,(select GoodsName from tGoods where GoodsID=A.GoodsID)as GoodsName,Model,Spec,Price,UnitName,OutNums,Number,CurStoreNums,Moneys from #BuyApplyDetail A

		--ԭ��
		if((select Count(*) from  #BuyApplyDetail where GoodsType=0)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,0)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A where GoodsType=0
		end
		--���Ʒ
		if((select Count(*) from  #BuyApplyDetail where GoodsType=1)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,1)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A where GoodsType=1
		end
		--���
		if((select Count(*) from  #BuyApplyDetail where GoodsType=3)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'�������Ͽ�治��',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,3)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A where GoodsType=3
		end
	end

GO
	If Exists ( Select name From sysobjects Where name = 'sp_GetCalcFee' and type='P')
		Drop Procedure [storage].[sp_GetCalcFee]
GO
/*

���ܣ�
	�����ɹ�������õ����ɹ����ļƼ�����

������
	@SheetID    --�ɹ���ID
	@Fee        --�Ƽ�����

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_GetCalcFee]
	@SheetID   int,
	@Fee       float out
AS
	select @Fee = sum(B.number * IsNull(E.nums,1) * C.calcfee) from tsendworker as A
	inner join tsendworkerdetail as B on A.sheetid=B.sheetid 
	inner join tcalcunit as C on B.productid=C.goodsid
	inner join tGoods as F on F.GoodsID=B.productid
	inner join tunit as D on B.unit=D.unitname
	left join tunitconversion as E on D.unitid=E.unitid
	where A.sheetid=@SheetID and D.GoodsType=F.GoodsType

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CreateCalcWage' and type='P')
		Drop Procedure [storage].[sp_CreateCalcWage]
GO
/*

���ܣ�
	�����ɹ������鹤�˷����Ʒ��ϸ

������
	@SheetID       --�ɹ���ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_CreateCalcWage]
	@SheetID int   --�ɹ���ID
AS
	EXEC('insert into tCalcDetail(detailid,goodsid,unit,number)
		select D.detailid, B.productid,B.unit,0 from tsendworker A
		inner join tsendworkerdetail B on B.sheetid=A.sheetid
		inner join tCalcSheet C on C.SendWorkID=A.SheetID
		left join tcalcsheetdetail D on D.sheetid=C.sheetid
		where C.pNo = A.pNo and A.sheetid='+@SheetID+'')

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CalcWage' and type='P')
		Drop Procedure [storage].[sp_CalcWage]
GO
/*

���ܣ�
	���ݼƼ������ɹ��˼Ƽ�����

������
	@SheetID      --�Ƽ���ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_CalcWage]
	@SheetID    int          --�Ƽ���ID
AS
	select B.EmpID,B.EmpName,sum(C.Number*IsNull(G.nums,1)*D.CalcFee)as ManFee into #CalcWage from tCalcSheet as A
	inner join tCalcSheetDetail as B on B.SheetID=A.SheetID
	inner join tCalcDetail as C on C.DetailID=B.DetailID
	inner join tCalcUnit as D on D.GoodsID=C.GoodsID
	inner join tGoods as E on E.GoodsID=C.GoodsID
	inner join tUnit as F on C.Unit=F.UnitName
	left join tUnitConversion as G on G.UnitID=F.UnitID
	where A.SheetID=@SheetID and E.GoodsType=F.GoodsType
	GROUP BY B.EmpID,B.EmpName

	update tCalcSheetDetail set ManFee=A.ManFee from #CalcWage A
	where tCalcSheetDetail.EmpID =A.EmpID and tCalcSheetDetail.SheetID=@SheetID

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CreateCalcWageAdd' and type='P')
		Drop Procedure [storage].[sp_CreateCalcWageAdd]
GO
/*
���ܣ�
	�����ɹ�������׷�ӵĹ��˷����Ʒ��ϸ

������
	@SheetID          --�ɹ���ID

���أ�

�����㷨��
*/
CREATE PROCEDURE [storage].[sp_CreateCalcWageAdd]
	@SheetID  int,           --�ɹ���ID
	@EmpIDs   varchar(50)    --׷�ӹ���ID����
AS
	EXEC('insert into tCalcDetail(detailid,goodsid,unit,number)
		select D.detailid, B.productid,B.unit,0 from tsendworker A
		inner join tsendworkerdetail B on B.sheetid=A.sheetid
		inner join tCalcSheet C on C.SendWorkID=A.SheetID
		left join tcalcsheetdetail D on D.sheetid=C.sheetid
		where D.EmpID in('+@EmpIDs+') and C.pNo = A.pNo and A.sheetid='+@SheetID)

GO
	If Exists ( Select name From sysobjects Where name = 'sp_CostOfProductDetail' and type='P')
		Drop Procedure [storage].[sp_CostOfProductDetail]
GO
/*

���ܣ�
	�����ɱ�ͳ����ϸ��Ϣ

������
	@pNo       --��Ʒ����
	@CostType  --ͳ������

���أ�
	�������ݼ�
*/
CREATE PROCEDURE [storage].[sp_CostOfProductDetail]
	@pNo      varchar(20),  --��Ʒ����
	@CostType int           --ͳ������
AS

	declare @Material1 int  --ԭ�ϳɱ�
	declare @Material2 int  --����ɱ�
	declare @Material3 int  --����ɱ�
	declare @Material  int  --�����ϳɱ�
	declare @Calc      int  --�Ƽ��ɱ�
	declare @Eq        int  --�豸����

	--���ϳɱ�����λ���������ϳɱ�*�����˲�Ʒ������*��λ����ֵ
	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,G.Price,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType into #CostMaterial from tProductPlan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where E.GoodsType=2 and A.pNo=@pNo
	if(@CostType=0)
	begin
		select SourceNo as �������,SourceName as ��������,Model as �ͺ�,Spec as ���,Unit as ��λ,Price as �۸�,Number as ����,CurStoreNums as ��ǰ�����,(Price*Number)as ���,(Case GoodsType when 0 then 'ԭ��' when 1 then '���Ʒ' else '���' end )as �������� from #CostMaterial
		UNION
		select GoodsCode as �������,GoodsName as ��������,Model as �ͺ�,Spec as ���,UnitName as ��λ,Price as �۸�,OutNums as ����,CurStoreNums as ��ǰ�����,(Price*OutNums)as ���,(Case GoodsType when 0 then 'ԭ��' when 1 then '���Ʒ' else '���' end )as �������� from tGetMaterialDetail where BillofTakeoutID in(select BillofTakeoutID from tGetMaterial where TakeOutType=1 and pNo=@pNo)
	end
	else if(@CostType=1)
	begin
		select SourceNo as �������,SourceName as ��������,Model as �ͺ�,Spec as ���,Unit as ��λ,Price as �۸�,Number as ����,CurStoreNums as ��ǰ�����,(Price*Number)as ���,(Case GoodsType when 0 then 'ԭ��' else '���Ʒ' end )as �������� from #CostMaterial where GoodsType<2
	end
	else if(@CostType=2)
	begin
		select SourceNo as �������,SourceName as ��������,Model as �ͺ�,Spec as ���,Unit as ��λ,Price as �۸�,Number as ����,CurStoreNums as ��ǰ�����,(Price*Number)as ���,(Case GoodsType when 3 then '���' else '��Ʒ' end )as �������� from #CostMaterial where GoodsType=3
	end
	else if(@CostType=3)
	begin
		select GoodsCode as �������,GoodsName as ��������,Model as �ͺ�,Spec as ���,UnitName as ��λ,Price as �۸�,OutNums as ����,CurStoreNums as ��ǰ�����,(Price*OutNums)as ���,(Case GoodsType when 0 then 'ԭ��' when 1 then '���Ʒ' else '���' end )as �������� from tGetMaterialDetail where BillofTakeoutID in(select BillofTakeoutID from tGetMaterial where TakeOutType=1 and pNo=@pNo)
	end

GO
