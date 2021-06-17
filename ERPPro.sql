USE KpowerERP
GO
	If Exists ( Select name From sysobjects Where name = 'sp_CommQueryProc' and type='P')
		Drop Procedure [storage].[sp_CommQueryProc]
GO
/*

功能：
	执行SQL语句查询分页的公共存储过程。

参数：
	@pSQL	varchar(8000)	SQL语句
	@pIDCol	varchar(50)		ID列名
	@pCurPage	int = 1		当前页
	@pPageSize	int = 20	页大小

返回：
	返回所有子类的ID串，多个ID用逗号分隔
*/
CREATE PROCEDURE [storage].[sp_CommQueryProc]
(
	@pSQL varchar(8000),	--SQL语句
	@pIDCol varchar(50),	--ID列名
	@pOrder varchar(500)='',	--排序字串
	@pCurPage int = 1,	--当前页
	@pPageSize int = 20,	--页大小
	@pRecNums int output,	--记录数
	@pRecPages int output	--记录页数
	
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

	--插入当前页及以前的数据的ID值到临时表
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
		set @pCurPage = @Pages			--传入的当前页号大于总页数的情况的意外处理

	set @RecStart = (@pCurPage-1) * @pPageSize + 1	--设置显示其实区域
	set @RecEnd = @pCurPage * @pPageSize		--设置显示终止区域

	set @pRecNums = @MaxCount		--记录数
	set @pRecPages = @Pages		--记录页数

	--把临时表中的数据与子集中的数据匹配
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
功能：
	添加生产成品质检报告

参数：
	@proNO	产品编号

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddQCRecord]
	@sID        varchar(50), --sID集合
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
功能：
	添加生产成品原料配置单

参数：
	@sID        sID集合
	@productID  产品ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddProductInstall]
	@sID        varchar(50), --sID集合
	@InsID      int
AS
	EXEC ('insert into tProductInstallDetail(InsID,productID,sourceNo,sourceName,Model,spec,unit,number,GoodsType) 
	select InsID='+@InsID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,0,GoodsType from tGoods
	where GoodsID in ('+@sID+')')  --使用集合必须用EXEC执行SQL语句，在此只能用sID，而不能再使用productID了作为集合字段

GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddCrafRoute' and type='P')
		Drop Procedure [storage].[sp_AddCrafRoute]
GO
/*

功能：
	添加工艺路线明细

参数：
	@sID        sID集合
	@productID  产品ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddCrafRoute]
	@sID     varchar(50), --工序名称ID集合    
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

功能：
	添加主生产计划单明细

参数：
	@sID        sID集合
	@SheetID    主生产计划单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddMainPlanDetail]
	@sID      varchar(50), --ID集合    
	@SheetID  int          --主生产计划单ID
	
AS    
	EXEC ('insert into tProductMainPlanDetail(SheetID,GoodsID,GoodsCode,GoodsName,Model,Spec,Unit,Price,pNumber,fNumber) 
		select SheetID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,Price,Nums,0 from tGoods
		where GoodsID in ('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_AddPlanDetail' and type='P')
		Drop Procedure [storage].[sp_AddPlanDetail]
GO
/*
功能：
	添加生产请求单明细

参数：
	@sID        sID集合
	@SheetID    生产请求单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddPlanDetail]
	@sID      varchar(50), --ID集合    
	@SheetID  int          --生产请求单ID
	
AS    
	EXEC ('insert into tProductPlanDetail(SheetID,ProID,ProductNo,ProductName,Model,Spec,Unit,Number,Price) 
		select SheetID='+@SheetID+',GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,Nums,Price from tGoods
		where GoodsID in ('+@sID+')')
GO
	If Exists ( Select name From sysobjects Where name = 'sp_CreatePdSendWorker' and type='P')
		Drop Procedure [storage].[sp_CreatePdSendWorker]
GO
/*
功能：
	由生产计划单生成派工单

参数：
	@SheetNo     --派工单编号
	@PlanID      --计划单ID
	@DetailID    --计划单明细ID集合

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_CreatePdSendWorker]
	@SheetNo     varchar(50),  --派工单编号
	@PlanID      int,          --计划单ID
	@DetailID    varchar(50)   --计划单明细ID集合
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

功能：
	添加采购申请单

参数：
	@sID         --货物ID集合
	@SheetID     --申请单ID

返回：

基本算法：
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

功能：
	添加生产派工单

参数：
	@sID         --货物ID集合
	@SheetID     --派工单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddSendWorker]
	@sID        varchar(50), --sID集合
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

功能：
	添加计件单明细

参数：
	@sID        sID集合
	@SheetID    计件单单据ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_AddPdCalcDetail]
	@sID      varchar(50), --员工名称ID集合    
	@SheetID  int          --计件单单据ID
	
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

功能：
	由派工单进行物料分析生成领料单

参数：
	@SheetNo     --生产领料单号
	@MakeBillMan --制单人
	@SheetID     --生产派工单ID

返回：

基本算法：
*/
CREATE  PROCEDURE  [storage].[sp_CreateGetMaterial]
	@SheetNo     varchar(20),         --生产领料单号
	@MakeBillMan varchar(20),         --制单人
	@SheetID     int                  --生产派工单ID	
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
		--原料
		if((select Count(*) from  #GetMaterial where GoodsType<2)>0)
		begin
			insert into tGetMaterial(BillNO,MakeBillMan,MakeBillDate,pNo,ClassID,TakeoutType,SendWorkID)
			select @SheetNoY,@MakeBillMan,getdate(),@pNo,ClassID,0,SheetID from tSendWorker where SheetID=@SheetID
			set @ID = @@IDENTITY

			insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,GoodsName,Model,Spec,Price,pNo,OutNums,UnitName,CurStoreNums,GoodsType,CustID)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Price,@pNo,Number,Unit,CurStoreNums,GoodsType,CustID from #GetMaterial where GoodsType<2
		end

		--配件
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

功能：
	添加生产领料单

参数：
	@sID
	@SheetID    --生产领料单ID

返回：

基本算法：
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

功能：
	生产成本核算

参数：
	@pNo  --产品批号

返回：

基本算法：
*/
CREATE  PROCEDURE [storage].[sp_CostOfProduct]
	@pNo      varchar(20)  --产品批号
AS

	declare @Material1 int  --原料成本
	declare @Material2 int  --配件成本
	declare @Material3 int  --超领成本
	declare @Material  int  --总物料成本
	declare @Calc      int  --计件成本
	declare @Eq        int  --设备费用
	declare @AllCost   int  --订单毛利
	declare @Sale      int  --销售金额
	declare @Cost      int  --订单毛利

	--物料成本，单位数量的物料成本*生产此产品的数量*单位换算值
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

	--计件成本
	select @Calc= sum(ToManFee) from tCalcSheet where pNo=@pNo

	--统计设备费用，单位数量的设备费用*生产此产品的数量*单位换算值
	select C.ProductID,C.ProductNo,C.ProductName,C.ToFee,IsNull(F.Nums,1)as Nums,B.Number into #EqFee from tProductPlan as A 
	inner join tProductPlanDetail as B on A.SheetID = B.SheetID
	inner join tCrafRoute as C on B.ProID = C.ProductID
	inner join tGoods as D on D.GoodsID  = C.ProductID
	inner join tUnit as E on B.Unit = E.UnitName
	left join tUnitConversion F on F.UnitID = E.UnitID
	where E.GoodsType=2 and A.pNo=@pNo
	select @Eq = sum(ToFee*Number*Nums) from #EqFee

	--从生产请求单中统计
	select @Sale = sum(TotalMoney) from tProductPlan where pNo=@pNo

	set @AllCost=@Material+@Calc+@Eq
	set @Cost = @Sale -@AllCost

	--输出结果集
	select @pNo AS pNo,IsNull(@Material1,0) AS Material1,IsNull(@Material2,0) AS Material2,IsNull(@Material3,0) AS Material3,IsNull(@Material,0) AS Material,IsNull(@Calc,0) AS Calc,IsNull(@Eq,0) AS Eq,IsNull(@AllCost,0) AS AllCost,@Sale AS Sale,IsNull(@Cost,0) AS Cost

GO
	If Exists ( Select name From sysobjects Where name = 'sp_MaterialCount' and type='P')
		Drop Procedure [storage].[sp_MaterialCount]
GO
/*

功能：
	生产请求能力分析

参数：
	@SheetID  int                  --生产请求单ID

返回：

基本算法：
*/
CREATE  PROCEDURE [storage].[sp_MaterialCount]
	@SheetID  int                  --生产请求单ID
AS
	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType into #MaterialCount from tproductplan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where E.GoodsType=2 and A.sheetid=@SheetID --E.GoodsType=G.GoodsType and 

	--过滤重复的货品
	select ProductID,SourceNo,SourceName,Model,Spec,Unit,sum(Number)as Number,CurStoreNums,GoodsType 
	from #MaterialCount group by ProductID,SourceNo,SourceName,Model,Spec,Unit,CurStoreNums,GoodsType
GO
	If Exists ( Select name From sysobjects Where name = 'sp_MaterialCountApply' and type='P')
		Drop Procedure [storage].[sp_MaterialCountApply]
GO
/*

功能：
	生产请求能力分析生成请购单

参数：
	@SheetID      --生产请求单ID
	@SheetNo      --请购单编号
	@ApplyPerson  --请购人
	@TablePerson  --请购单制单人
	@DeptID       --请购单部门
	@ApplyCount   --输出库存不足的物料记录数

返回：

基本算法：
*/
CREATE  PROCEDURE [storage].[sp_MaterialCountApply]
	@SheetID      int,             --生产请求单ID
	@SheetNo      varchar(20),     --请购单编号
	@ApplyPerson  varchar(20),     --请购人
	@TablePerson  varchar(20),     --请购单制单人
	@DeptID       varchar(20),     --请购单部门
	@ApplyCount   int out          --输出库存不足的物料记录数
AS
	declare @ID   int
	declare @SequenceNum  int      --序号

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
		--values(@SheetNo,getdate(),'生产领料库存不足',@ApplyPerson,@DeptID,@TablePerson,getdate())
		--set @ID = @@IDENTITY

		--insert into tBuyApplyDetail(SheetID,GoodsID,GoodsNo,GoodsName,Model,Spec,UnitName,UseNumber,Number,CurStoreNums,Price,Moneys)
		--select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,0,0 from #ApplyDetail

		--原料
		if((select Count(*) from  #ApplyDetail where GoodsType=0)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,0)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail where GoodsType=0
		end
		--半成品
		if((select Count(*) from  #ApplyDetail where GoodsType=1)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,1)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail where GoodsType=1
		end
		--配件
		if((select Count(*) from  #ApplyDetail where GoodsType=3)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,3)
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

功能：
	查询接受方的信息

参数：


返回：

基本算法：
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
功能：
	删除公文

参数：
	@docid  公文ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_DelDocMain]
	@docid int
AS
	delete from tReInfo where DocID=@docid  --回复
	delete from tDocRs where DocID=@docid   --公文明细
	delete from tDocMain where DocID=@docid --公文主表
GO
	If Exists ( Select name From sysobjects Where name = 'sp_GetMaterialBuyApply' and type='P')
		Drop Procedure [storage].[sp_GetMaterialBuyApply]
GO
/*

功能：
	将生产领料单中在库存中不足的物料生成请购单

参数：
	@SheetID      --生产领料单ID
	@SheetNo      --请购单编号
	@ApplyPerson  --请购人
	@TablePerson  --制单人
	@BuyCount     --请购物料记录数

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_GetMaterialBuyApply]
	@SheetID      int,           --生产领料单ID
	@SheetNo      varchar(20),   --请购单编号
	@ApplyPerson  varchar(20),   --请购人
	@TablePerson  varchar(20),   --制单人
	@BuyCount     int out        --请购物料记录数
AS
	declare @ID   int
	declare @SequenceNum  int    --序号

	select GoodsID,GoodsCode,GoodsName,Model,Spec,Price,UnitName,OutNums,(OutNums-CurStoreNums) as Number,CurStoreNums,(Price*(OutNums-CurStoreNums))as Moneys,GoodsType
	into #BuyApplyDetail from tGetMaterialDetail 
	where BillOfTakeoutID = @SheetID and OutNums>CurStoreNums

	select @BuyCount=Count(*) from  #BuyApplyDetail
	if(@BuyCount>0)
	begin
		--insert into tBuyApply(SheetNo,ApplyTime,BuyReason,ApplyPerson,TablePerson,WriteTime)
		--values(@SheetNo,getdate(),'生产领料库存不足',@ApplyPerson,@TablePerson,getdate())
		--set @ID = @@IDENTITY

		--insert into tBuyApplyDetail(SheetID,GoodsID,GoodsNo,GoodsName,Model,Spec,Price,UnitName,UseNumber,Number,CurStoreNums,Moneys)
		--select @ID,GoodsID,GoodsCode,(select GoodsName from tGoods where GoodsID=A.GoodsID)as GoodsName,Model,Spec,Price,UnitName,OutNums,Number,CurStoreNums,Moneys from #BuyApplyDetail A

		--原料
		if((select Count(*) from  #BuyApplyDetail where GoodsType=0)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,0)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A where GoodsType=0
		end
		--半成品
		if((select Count(*) from  #BuyApplyDetail where GoodsType=1)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,1)
			set @ID = @@IDENTITY

			insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
			select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A where GoodsType=1
		end
		--配件
		if((select Count(*) from  #BuyApplyDetail where GoodsType=3)>0)
		begin
			SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
			insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
			values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,3)
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

功能：
	根据派工单班组得到此派工单的计件费用

参数：
	@SheetID    --派工单ID
	@Fee        --计件费用

返回：

基本算法：
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

功能：
	根据派工单班组工人分配产品明细

参数：
	@SheetID       --派工单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_CreateCalcWage]
	@SheetID int   --派工单ID
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

功能：
	根据计件单生成工人计件工资

参数：
	@SheetID      --计件单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_CalcWage]
	@SheetID    int          --计件单ID
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
功能：
	根据派工单班组追加的工人分配产品明细

参数：
	@SheetID          --派工单ID

返回：

基本算法：
*/
CREATE PROCEDURE [storage].[sp_CreateCalcWageAdd]
	@SheetID  int,           --派工单ID
	@EmpIDs   varchar(50)    --追加工人ID集合
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

功能：
	生产成本统计详细信息

参数：
	@pNo       --产品批号
	@CostType  --统计类型

返回：
	返回数据集
*/
CREATE PROCEDURE [storage].[sp_CostOfProductDetail]
	@pNo      varchar(20),  --产品批号
	@CostType int           --统计类型
AS

	declare @Material1 int  --原料成本
	declare @Material2 int  --配件成本
	declare @Material3 int  --超领成本
	declare @Material  int  --总物料成本
	declare @Calc      int  --计件成本
	declare @Eq        int  --设备费用

	--物料成本，单位数量的物料成本*生产此产品的数量*单位换算值
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
		select SourceNo as 货物编码,SourceName as 货物名称,Model as 型号,Spec as 规格,Unit as 单位,Price as 价格,Number as 数量,CurStoreNums as 当前库存量,(Price*Number)as 金额,(Case GoodsType when 0 then '原料' when 1 then '半成品' else '配件' end )as 货物类型 from #CostMaterial
		UNION
		select GoodsCode as 货物编码,GoodsName as 货物名称,Model as 型号,Spec as 规格,UnitName as 单位,Price as 价格,OutNums as 数量,CurStoreNums as 当前库存量,(Price*OutNums)as 金额,(Case GoodsType when 0 then '原料' when 1 then '半成品' else '配件' end )as 货物类型 from tGetMaterialDetail where BillofTakeoutID in(select BillofTakeoutID from tGetMaterial where TakeOutType=1 and pNo=@pNo)
	end
	else if(@CostType=1)
	begin
		select SourceNo as 货物编码,SourceName as 货物名称,Model as 型号,Spec as 规格,Unit as 单位,Price as 价格,Number as 数量,CurStoreNums as 当前库存量,(Price*Number)as 金额,(Case GoodsType when 0 then '原料' else '半成品' end )as 货物类型 from #CostMaterial where GoodsType<2
	end
	else if(@CostType=2)
	begin
		select SourceNo as 货物编码,SourceName as 货物名称,Model as 型号,Spec as 规格,Unit as 单位,Price as 价格,Number as 数量,CurStoreNums as 当前库存量,(Price*Number)as 金额,(Case GoodsType when 3 then '配件' else '成品' end )as 货物类型 from #CostMaterial where GoodsType=3
	end
	else if(@CostType=3)
	begin
		select GoodsCode as 货物编码,GoodsName as 货物名称,Model as 型号,Spec as 规格,UnitName as 单位,Price as 价格,OutNums as 数量,CurStoreNums as 当前库存量,(Price*OutNums)as 金额,(Case GoodsType when 0 then '原料' when 1 then '半成品' else '配件' end )as 货物类型 from tGetMaterialDetail where BillofTakeoutID in(select BillofTakeoutID from tGetMaterial where TakeOutType=1 and pNo=@pNo)
	end

GO
