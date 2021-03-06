SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据指定客户ID、指定年份及超额销售金额，计算出超额返点金额
参数：
	@pYear		年份
	@pCustomerID		客户ID
	@pFullMoney		超额销售金额
返回：
	销售超额部分的返点金额（元）
*/
CREATE FUNCTION [storage].[fnCalRakeOff]
 (
	@pYear	int,			--年份
	@pCustomerID int,			--客户ID
	@pFullMoney numeric(20,8)		--多余销售金额（万元）
)  
RETURNS numeric(20,8) AS  
BEGIN 
	if(@pFullMoney <= 0)
		return 0

	declare @Rate numeric(18,8)
	declare @Money numeric(18,8)

	set @Money = 0

	--获取该客户的超额销售返点率
	select
		@Rate = Rate
	from
		tRakeOff
	where
		[Year] = @pYear
		and CustomerID = @pCustomerID
		and LowValue <= @pFullMoney and UpperValue >= @pFullMoney

	--没有设置，则从通用超额销售返点设置表中提取
	if(@Rate is null) begin
		select
			@Rate = Rate
		from
			tCommRakeOff
		where
			[Year] = @pYear
			and LowValue <= @pFullMoney and UpperValue >= @pFullMoney
	end

	--均未设置超额销售返点率，则返回0
	if(@Rate is not null) begin
		set @Money = @pFullMoney * 10000 * (@Rate/100)	--计算超额部分返点金额
	end

	return @Money
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：比较两个数的大小，如果A>=B则返回 1；否则返回0。
输入参数：A，B
输出参数：A>=B 则返回1； A<B 则返回 0
*/
CREATE FUNCTION [storage].[fnCompareValue] ( @A float, @B float)  
RETURNS int AS  
BEGIN 
declare @result int

	if(@A>=@B)
		set @result=1
	else
		set @result=0

return @result
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据给定ID，获得分类名称

输入参数：@pClassID=分类ID

输入参数：员工姓名
*/

CREATE FUNCTION [Storage].[fnGeClassName] (@pClassID int)  
RETURNS varchar(100)  AS  
BEGIN 
   declare @ProClassName varchar(100)

if(@pClassID=0)
    Begin
	set @ProClassName='所有'
   end
else
  Begin
	set @ProClassName=''
	select @ProClassName=DataValue  from tBaseDataTree where DataID=@pClassID
  End
	return @ProClassName
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据给定ID，获得分类名称

输入参数：@pCsrID=客户ID

输入参数：客户姓名
*/

CREATE FUNCTION [Storage].[fnGeCustomerName] (@pCsrID int)  
RETURNS varchar(100)  AS  
BEGIN 
   declare @CustomerName varchar(100)


	set @CustomerName=''
	select @CustomerName=shortName  from tCustomer where CustomerID=@pCsrID
	return @CustomerName
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	根据指定货物类型（0-产品　1-半成品　2-成品）返回货物最大序列号。

参数：
	@pGoodsType		int	货物类别

返回：
	int	最大序列号
*/
CREATE  FUNCTION [storage].[fnGeGoodstMaxSque] (
	@pGoodsType int
)  
RETURNS int
AS  
BEGIN 
	declare @NewNO int
	select @NewNO = isnull(max(SequenceNum),0)+1 from tGoods where GoodsType=@pGoodsType
	return @NewNO
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：获取基础地区表tArea，某个父类的所有子类的ID字符串

输入参数：       @ParentAreaID=根类地区ID
		@pDepthlength=进入几级进深		若不需要设置进深度则@pDepthlength=0
		@pCurlength=当前进深等级		使用时，此值始终输入0
结果：返回所有子类的ID串，多个ID用逗号分隔
*/
CREATE FUNCTION [storage].[fnGetAreaClassStr] (@pParentAreaID int,@pDepthlength int ,@pCurlength int =0)  
RETURNS varchar(400)  AS  
BEGIN 
	declare @ID int
	declare @classStr varchar(200)
	declare @tmpClassID int


	set @classStr=convert(varchar(50),@pParentAreaID)

if(@pParentAreaID=0)
  begin

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		


		declare tArea_cursor  Cursor for
				select AreaID from  tArea where ParentAreaID is null
		    
			open tArea_cursor

			fetch next  from tArea_cursor into @tmpClassID
			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetAreaClassStr(@tmpClassID,@pDepthlength,@pCurlength+1)
					fetch next  from tArea_cursor into @tmpClassID
				end
			end

			close tArea_cursor
		deallocate tArea_cursor
	END

end 
else
begin

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		


		declare tArea_cursor  Cursor for
				select AreaID from  tArea  where ParentAreaID=@pParentAreaID
		    
			open tArea_cursor

			fetch next  from tArea_cursor into @tmpClassID
			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetAreaClassStr(@tmpClassID,@pDepthlength,@pCurlength+1)
					fetch next  from tArea_cursor into @tmpClassID
				end
			end

			close tArea_cursor
		deallocate tArea_cursor
	END


end
	return @classStr
END












GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取并返回树形表中某节点的所有子节点（递归）的ID组成字符串（以逗号分隔）

参数：
	 @pParentDataID	int	父节点数据ID
	@pDepthlength		int	进入几级进深		若不需要设置进深度则@pDepthlength=0
	@pCurlength		int	当前进深等级		使用时，此值始终输入0
	@pDataType		int	数据类别（比如：产品类别、半成品类别、成品类别）

返回：
	返回所有子节点的ID串，多个ID用逗号分隔
*/
CREATE FUNCTION [storage].[fnGetBaseDataClassStr]
(
	@pParentDataID int,
	@pDepthlength int ,
	@pCurlength int =0
)  
RETURNS 
	varchar(5000) 
 AS  
BEGIN 
	declare @ID int
	declare @classStr varchar(200)
	declare @tmpDataID int

	set @classStr=convert(varchar(50),@pParentDataID)

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		
		declare tData_cursor  Cursor for
			select DataID from  tBaseDataTree  where ParentDataID=@pParentDataID
			open tData_cursor

			fetch next  from tData_cursor into @tmpDataID
			while(@@fetch_status=0)
			begin
				if(@tmpDataID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetBaseDataClassStr(@tmpDataID,@pDepthlength,@pCurlength+1)
					fetch next  from tData_cursor into @tmpDataID
				end
			end

			close tData_cursor
		deallocate tData_cursor
	END

	return @classStr
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*


功能：
	获取并返回树形表中某节点的所有子节点（递归）的ID组成的TABLE

参数：
	 @pParentDataID	int	父节点数据ID（如果是根节点，则用0表示）
	@pDataType		int	数据类别（比如：产品类别、半成品类别、成品类别）

结果：
	以Table 方式输出
*/
CREATE FUNCTION [storage].[fnGetBaseDataTreeTable]
 (
	@pParentDataID int,
	@pDataType int
)  
RETURNS 
	@RetTable Table(DataID numeric, DataValue varchar(50))
AS  
BEGIN 
	--select dbo.fnGetClassStr(1,2)
	--下面是对分类的递归分类串进行拆分，然后根据每个ID值，将对应的信息插入到TABLE中，然后返回出去
	declare @pStart int
	declare @pDataID varchar(20)
	declare @pDataList varchar(2000)
	declare @pTmpTable Table(DataID numeric, DataValue varchar(50))

if(@pParentDataID <> 0)
begin
	set @pDataList = storage.fnGetBaseDataClassStr(@pParentDataID,0,0) --获取递归的串，以字符串将子类集返回，多个分类用逗号分隔

	set @pStart=charindex(',',@pDataList)

	while(@pStart>0)
	begin
		set @pDataID=left(@pDataList,@pStart-1)
		Insert into @pTmpTable select	DataID,DataValue from tBaseDataTree where DataID=@pDataID
		set @pDataList=right(@pDataList,len(@pDataList)-@pStart)
		set @pStart=charindex(',',@pDataList)
	end

	if(@pDataList!='')
	BEGIN
		set @pDataID=@pDataList
		Insert into @pTmpTable select	DataID,DataValue from tBaseDataTree where DataID=@pDataID
	END

	Insert into @RetTable select * from @pTmpTable order by DataID asc
end
else
	insert into @RetTable select DataID,DataValue from tBaseDataTree where DataType = @pDataType
	
return
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取基础树型表tBaseDatatree，某个父类的所有子类的ID字符串
	tBaseDatatree表中的不同类型的数据通用

参数：
	@pClassID = 根类ID
	@pType = 信息类别

结果：
	返回所有子类的ID串，多个ID用逗号分隔
*/
CREATE FUNCTION [storage].[fnGetClassStr] (@pClassID int,@pType int)  
RETURNS varchar(400)  AS  
BEGIN 
	declare @ID int
	declare @classStr varchar(200)
	declare @tmpClassID int

	set @classStr=convert(varchar(50),@pClassID)
		
	declare tBaseData_cursor  Cursor for
		select dataID from  tBaseDatatree  where parentDataID=@pClassID and dataType=@pType
		open tBaseData_cursor

		fetch next  from tBaseData_cursor into @tmpClassID
		while(@@fetch_status=0)
		begin
			if(@tmpClassID!=null)
			begin
				set @classStr=@classStr+','+storage.fnGetClassStr(@tmpClassID,@pType)
				fetch next  from tBaseData_cursor into @tmpClassID
			end
		end
		
		close tBaseData_cursor
	deallocate tBaseData_cursor

	return @classStr
END

















GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：获取基础地区表tArea，某个父类的所有子类的ID字符串

输入参数：       @ParentAreaID=根类地区ID
		@pDepthlength=进入几级进深		若不需要设置进深度则@pDepthlength=0
		@pCurlength=当前进深等级		使用时，此值始终输入0
结果：返回所有子类的ID串，多个ID用逗号分隔
*/
CREATE FUNCTION [storage].[fnGetDeptClassStr] (@pParentAreaID int,@pDepthlength int ,@pCurlength int =0)  
RETURNS varchar(400)  AS  
BEGIN 
	declare @ID int
	declare @classStr varchar(200)
	declare @tmpClassID int

	set @classStr=convert(varchar(50),@pParentAreaID)

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		
		declare tArea_cursor  Cursor for
			select DeptID from  tDepartment  where ParentDeptID=@pParentAreaID
			open tArea_cursor

			fetch next  from tArea_cursor into @tmpClassID
			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetDeptClassStr(@tmpClassID,@pDepthlength,@pCurlength+1)
					fetch next  from tArea_cursor into @tmpClassID
				end
			end

			close tArea_cursor
		deallocate tArea_cursor
	END

	return @classStr
END












GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取货品在指定库房的库存量
参数：
	@pGoodsID		货品ID
	@pStoreHouseID	库房ID
返回：
	文字描述
*/
CREATE FUNCTION [storage].[fnGetGoodsStoreNums]
 (
	@pGoodsID as int,
	@pStoreHouseID as int
)  
RETURNS numeric(18,2) AS  
BEGIN 
	declare @Nums numeric(18,2)
	select @Nums = CurStoreNums from tProductStoreNums where GoodsID=@pGoodsID and StoreHouseID=@pStoreHouseID
	select @Nums = isnull(@Nums,0)

	return @Nums
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据指定货品ID，获取其货物类别（0-产品　1-半成品　2-成品）
参数：
	@pGoodsID		货品ID
返回：
	货物类别
*/
CREATE FUNCTION [Storage].[fnGetGoodsTypeOfGoods](@pGoodsID numeric)
RETURNS int
 AS
BEGIN
	declare @i int
	select @i = GoodsType from tGoods where GoodsID=@pGoodsID
	return @i
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

CREATE FUNCTION [Storage].[fnGetMaxBatchNo] (@pGoodsID int)  
RETURNS varchar(50) AS  
BEGIN 
	declare @pMaxBatchNo varchar(50)

	select @pMaxBatchNo=max(BatchNo) from tDetailOfPutin where GoodsID=@pGoodsID


	return @pMaxBatchNo
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	根据指定货物类型（0-产品　1-半成品　2-成品）返回入库单其最大序列号。

参数：
	@pGoodsType		int	货物类别

返回：
	int	最大序列号
*/
CREATE  FUNCTION [storage].[fnGetMaxSque] (
	@pGoodsType int
)  
RETURNS int
AS  
BEGIN 
	declare @NewNO int
	select @NewNO = isnull(max(SequenceNum),0)+1 from tBillOfPutin where GoodsType=@pGoodsType
	return @NewNO
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据指定货物类型（0-产品　1-半成品　2-成品）返回调拨单其最大序列号。

参数：
	@pGoodsType		int	货物类别

返回：
	int	最大序列号
*/
CREATE FUNCTION  [storage].[fnGetMaxSqueOfBillOfExchange] (
	@pGoodsType int
)  
RETURNS int
AS  
BEGIN 
	declare @NewNO int
	select @NewNO = isnull(max(SequenceNum),0)+1 from tBillOfExchange where GoodsType=@pGoodsType
	return @NewNO
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据指定货物类型（0-产品　1-半成品　2-成品）返回出库单其最大序列号。

参数：
	@pGoodsType		int	货物类别

返回：
	int	最大序列号
*/
CREATE FUNCTION  [storage].[fnGetMaxSqueOfBillOfTakeout] (
	@pGoodsType int
)  
RETURNS int
AS  
BEGIN 
	declare @NewNO int
	select @NewNO = isnull(max(SequenceNum),0)+1 from tBillOfTakeout where GoodsType=@pGoodsType
	return @NewNO
END



GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据指定货物类型（0-产品　1-半成品　2-成品）返回盘点表最大序列号。

参数：
	@pGoodsType		int	货物类别

返回：
	int	最大序列号
*/
CREATE FUNCTION  [storage].[fnGetMaxSqueOfCheckTable] (
	@pGoodsType int
)  
RETURNS int
AS  
BEGIN 
	declare @NewNO int
	select @NewNO = isnull(max(SequenceNum),0)+1 from tCheckTable where GoodsType=@pGoodsType
	return @NewNO
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：搜索tBillOfBuy中的顺序号，获取到新的顺序号

结果：返回生成的新的顺序号
*/
CREATE FUNCTION [storage].[fnGetNewBillOfBuyNo] ()  
RETURNS varchar(20) AS  
BEGIN 
	Declare @newNo varchar(50)
	SELECT @newNo= isnull(max(SequenceNum),0)+1 FROM tBillOfBuy
return @newNo
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：搜索tBillOfSell中的顺序号，获取到新的顺序号

结果：返回生成的新的顺序号
*/
CREATE FUNCTION [storage].[fnGetNewBillOfSellNo] ()  
RETURNS varchar(20) AS  
BEGIN 
	Declare @newNo varchar(50)
	SELECT @newNo= isnull(max(SequenceNum),0)+1 FROM tBillOfSell
return @newNo
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：搜索tOrder中的顺序号，获取到新的顺序号

结果：返回生成的新的顺序号
*/
CREATE FUNCTION [storage].[fnGetNewOrderOfSellNo] ()  
RETURNS varchar(20) AS  
BEGIN 
	Declare @newNo varchar(50)
	SELECT @newNo= isnull(max(SequenceNum),0)+1 FROM tOrder
return @newNo
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：搜索tSellBack中的顺序号，获取到新的顺序号

结果：返回生成的新的顺序号
*/
CREATE FUNCTION [storage].[fnGetNewSellBackNo] ()  
RETURNS varchar(20) AS  
BEGIN 
	Declare @newNo varchar(50)
	SELECT @newNo= isnull(max(SequenceNum),0)+1 FROM tSellBack
return @newNo
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

CREATE FUNCTION [Storage].[fnGetNewestSeller] (@CustomerID int)  
RETURNS varchar(50) AS  
BEGIN 
	declare @EmpName varchar(50)

	select top 1 @EmpName= EmpName from tBillOfSell join tEmployee on tBillOfSell.SellerID=tEmployee.EmpID where CustomerID=@CustomerID

	return @EmpName
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
获取客户所对应的最新销售人员的ID
*/
CREATE FUNCTION [Storage].[fnGetNewestSellerID] (@CustomerID int)  
RETURNS varchar(50) AS  
BEGIN 
	declare @EmpID varchar(50)

	select top 1 @EmpID= sellerID from tBillOfSell join tEmployee on tBillOfSell.SellerID=tEmployee.EmpID where CustomerID=@CustomerID

	return @EmpID
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据对象ID和模块名以及操作数据，产生操作操作的显示字串（带复选框）[复选框名称为模型ID]
参数：
	@pObjID		varchar(20)	对象ID；
	@pModelID	int		模块ID；
	@pOperator	varchar(20)	操作字串；
	@pWM		varchar(1)	对象名是依据模块ID还是员工ID（中干编号、角色编号）[W-员工  

M-模块]
返回：
	varchar(500)
*/

CREATE FUNCTION [Storage].[fnGetOperatorDispStr]
 (
	@pObjID	varchar(20),
	@pModelID	int,
	@pOperator	varchar(20),
	@pWM		varchar(1)
) 
RETURNS 
	varchar(2500)

BEGIN 
	declare @strOperator varchar(2500)
	declare @strFormName varchar(200)
	declare @i int

	if(@pWM = 'M')
		set @strFormName = 'op_' +  convert(varchar(20),@pModelID)
	else
		set @strFormName = 'op_' +  convert(varchar(20),@pObjID)

	if(@pOperator = '' or @pOperator = '0' or @pOperator is null)
	begin
		set @strOperator = ''
		set @strOperator = @strOperator + '<input type="checkbox" name="' + @strFormName 

+ '" value="Q">查询'
		set @strOperator = @strOperator + '<input type="checkbox" name="' + @strFormName 

+ '" value="A">新增'
		set @strOperator = @strOperator + '<input type="checkbox" name="' + @strFormName 

+ '" value="M">修改'
		set @strOperator = @strOperator + '<input type="checkbox" name="' + @strFormName 

+ '" value="D">删除'
		set @strOperator = @strOperator + '<input type="checkbox" name="' + @strFormName 

+ '" value="C">审核'
	end
	else
	begin
		set @strOperator = ''
		select @i = charindex('Q',@pOperator)
		if (@i > 0)
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="Q" checked>查询'
		else
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="Q">查询'

		select @i = charindex('A',@pOperator)
		if (@i > 0)
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="A" checked>新增'
		else
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="A">新增'

		select @i = charindex('M',@pOperator)
		if (@i > 0)
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="M" checked>修改'
		else
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="M">修改'

		select @i = charindex('D',@pOperator)
		if (@i > 0)
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="D" checked>删除'
		else
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="D">删除'

		select @i = charindex('C',@pOperator)
		if (@i > 0)
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="C" checked>审核'
		else
			set @strOperator = @strOperator + '<input type="checkbox" name="' + 

@strFormName + '" value="C">审核'
		
	end

	return(@strOperator)

END










GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：根据给定的分类ID，以递归的方式，将分类表tArea的归属信息显示出来
结果：返回连接的字符串
输入参数：@pParentID=分类ID
*/
CREATE FUNCTION [storage].[fnGetParentAreaStr] (@pParentID int)  
RETURNS varchar(200)  AS  
BEGIN 
	declare @pParentName varchar(50)  --获取类名
	declare @pGetParentID int	--获取父类ID
	declare @renValue varchar(200) --返回的字符串

	select @pParentName=AreaName,@pGetParentID=ParentAreaID from tArea where AreaID=@pParentID
		
	set @renValue=isnull(@pParentName,'')

	if (@pGetParentID != null)
		 set  @renValue = storage.fnGetParentAreaStr(@pGetParentID)+'->'+@renValue

	return @renValue

END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据给定的分类ID，以递归的方式，将分类表tBaseDataTree的归属信息显示出来
结果：返回连接的字符串
输入参数：@pParentID=分类ID；@pType=分类信息的类型ID
*/
CREATE FUNCTION [storage].[fnGetParentClassStr] (@pParentID int,@pType int)  
RETURNS varchar(200)  AS  
BEGIN 
	declare @pParentName varchar(50)  --获取类名
	declare @pGetParentID int	--获取父类ID
	declare @renValue varchar(200) --返回的字符串

	select @pParentName=DataValue,@pGetParentID=ParentDataID from tBaseDataTree where DataType=@pType and dataID=@pParentID
		
	set @renValue=isnull(@pParentName,'')

	if (@pGetParentID != null)
		 set  @renValue = storage.fnGetParentClassStr(@pGetParentID,@pType)+'->'+@renValue

	return @renValue

END



GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：根据给定的分类ID，以递归的方式，将分类表tCompany的归属信息显示出来
结果：返回连接的字符串
输入参数：@pParentID=分类ID
*/
CREATE FUNCTION [storage].[fnGetParentCompanyStr] (@pParentID int)  
RETURNS varchar(200)  AS  
BEGIN 
	declare @pParentName varchar(50)  --获取类名
	declare @pGetParentID int	--获取父类ID
	declare @renValue varchar(200) --返回的字符串

	select @pParentName=CompName,@pGetParentID=ParentCompID from tCompany  where CompID=@pParentID
		
	set @renValue=isnull(@pParentName,'')

	if (@pGetParentID != null)
		 set  @renValue = storage.fnGetParentCompanyStr(@pGetParentID)+'->'+@renValue

	return @renValue

END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*


功能：根据给定的分类ID，以递归的方式，将分类表tDepartment的归属信息显示出来
结果：返回连接的字符串
输入参数：@pParentID=分类ID
*/
CREATE FUNCTION [storage].[fnGetParentDeptStr] (@pParentID int)  
RETURNS varchar(200)  AS  
BEGIN 
	declare @pParentName varchar(50)  --获取类名
	declare @pGetParentID int	--获取父类ID
	declare @renValue varchar(200) --返回的字符串

	select @pParentName=DeptName,@pGetParentID=ParentDeptID from tDepartment  where DeptID=@pParentID
		
	set @renValue=isnull(@pParentName,'')

	if (@pGetParentID != null)
		 set  @renValue = storage.fnGetParentDeptStr(@pGetParentID)+'->'+@renValue

	return @renValue

END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

CREATE FUNCTION [Storage].[fnGetProClassID] (@pProcID int)  
RETURNS int  AS  
BEGIN 
	declare @pProcClassID int
	set @pProcClassID=0

	select @pProcClassID=goodsTypeID from tgoods where GoodsID=@pProcID


	return @pProcClassID
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/* 	
功能：根据客户，选择与客户所对应的销售单品 单价。如果没有对客户设置特定价格，则按统计单价返回

输入参数：
		@pGoodsID= 产品ID
		@pCustomerID=客户ID

输出参数：
		@getPrice 根据查询得到的实际价格

*/

CREATE  Function [storage].[fnGetProductPrice](@pGoodsID int,@pCustomerID int)
Returns numeric(12,2) as

Begin
	declare @getPrice numeric(12,2) --获取产品价格
	
	select @getPrice=Price  from tCustomerProductPrice where CustomerID=@pCustomerID and GoodsID=@pGoodsID

	if(@getPrice is null)
		select @getPrice=price from tgoods where GoodsID=@pGoodsID

	if(@getPrice is null)
		set @getPrice=0

	return @getPrice
End


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取入库类别（0-正常入库 1-退货入库 2-盘盈入库）。
参数：
	@pPutinType	入库类别
返回：
	文字描述
*/
CREATE FUNCTION [storage].[fnGetPutinTypeName]
 (
	@pPutinType as int
)  
RETURNS varchar(100) AS  
BEGIN 
	declare @sName as varchar(100)
	set @sName = case @pPutinType when 0 then '正常入库' when 1 then '<font color=red>退货入库</font>' when 2 then '<font color=green>盘盈入库</font>'  when 3 then '<font color=Orange>调拨入库</font>' end

	return @sName
END



GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据对象ID和模块名以及操作数据，产生操作范围的显示字串（带单选钮）
参数：
	@pObjID		varchar(20)	对象ID；
	@pModelID	int		模块ID；
	@pRange		varchar(20)	操作范围字串；
	@pWM		varchar(1)	对象名是依据模块ID还是员工ID（中干编号、角色编号）[W-员工  M-模块]
返回：
	varchar(250)
*/

CREATE FUNCTION [Storage].[fnGetRangeDispStr]
 (
	@pObjID		varchar(20),
	@pModelID		int,
	@pRange		varchar(20),
	@pWM			varchar(2)
) 
RETURNS 
	varchar(250)

BEGIN 
	declare @strRange varchar(250)
	declare @strFormName varchar(20)
	declare @i int

	if(@pWM = 'M')
		set @strFormName = 'ra_' +  convert(varchar(20),@pModelID)
	else
		set @strFormName = 'ra_' +  convert(varchar(20),@pObjID)

	set @strRange = ''

	if(@pRange = '' or @pRange = '0' or @pRange is null)
	begin
		set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="A">所有'
		set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="L">本部门'
		set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="P">本人'
	end
	else
	begin
		if(@pRange = 'A')
		begin
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="A" checked>所有'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="L">本部门'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="P">本人'
		end
		if(@pRange = 'L')
		begin
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="A">所有'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="L" checked>本部门'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="P">本人'
		end
		if(@pRange = 'P')
		begin
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="A">所有'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="L">本部门'
			set @strRange = @strRange + '<input type="radio" name="' + @strFormName + '" value="P" checked>本人'
		end
	
	end

	return(@strRange)

END







GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：获取基础库房表tStoreHouse，某个父类的所有子类的ID字符串

输入参数：       @pParentHouseID=根类库房ID
		@pDepthlength=进入几级进深		若不需要设置进深度则@pDepthlength=0
		@pCurlength=当前进深等级		使用时，此值始终输入0
结果：返回所有子类的ID串，多个ID用逗号分隔
*/
CREATE FUNCTION [storage].[fnGetStorageHouseClassStr] (@pParentHouseID int,@pDepthlength int ,@pCurlength int =0)  
RETURNS varchar(400)  AS  
BEGIN 
	declare @ID int
	declare @classStr varchar(200)
	declare @tmpClassID int


	set @classStr=convert(varchar(50),@pParentHouseID)

if(@pParentHouseID=0)
  begin

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		


		declare tHouse_cursor  Cursor for
				select StoreHouseID from  tStoreHouse where ParentHouseID is null
		    
			open tHouse_cursor

			fetch next  from tHouse_cursor into @tmpClassID
			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetStorageHouseClassStr(@tmpClassID,@pDepthlength,@pCurlength+1)
					fetch next  from tHouse_cursor into @tmpClassID
				end
			end

			close tHouse_cursor
		deallocate tHouse_cursor
	END

end 
else
begin

	if((@pDepthlength>@pCurlength) or (@pDepthlength=0)) --判断是否已经到达所要显示的进深度，若没到则继续查询
	BEGIN		


		declare tHouse_cursor  Cursor for
				select StoreHouseID from  tStoreHouse  where ParentHouseID=@pParentHouseID
		    
			open tHouse_cursor

			fetch next  from tHouse_cursor into @tmpClassID
			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin
					set @classStr=@classStr+','+storage.fnGetStorageHouseClassStr(@tmpClassID,@pDepthlength,@pCurlength+1)
					fetch next  from tHouse_cursor into @tmpClassID
				end
			end

			close tHouse_cursor
		deallocate tHouse_cursor
	END


end
	return @classStr
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	根据给定的分类ID，以递归的方式，将分类表tArea的归属信息显示出来
结果：
	返回连接的字符串

输入参数：
	@pParentID=分类ID
*/
CREATE FUNCTION [storage].[fnGetStoreHoueFullName] (@pParentID int)  
RETURNS varchar(200)  AS  
BEGIN 
	declare @pParentName varchar(50)  --获取类名
	declare @pGetParentID int	--获取父类ID
	declare @renValue varchar(200) --返回的字符串

	select @pParentName=HouseName,@pGetParentID=ParentHouseID from tStoreHouse where StoreHouseID=@pParentID
		
	set @renValue=isnull(@pParentName,'')

	if (@pGetParentID != null)
		 set  @renValue = storage.fnGetStoreHoueFullName(@pGetParentID)+'->'+@renValue

	return @renValue

END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	返回Table，记录按树状层次结构排序。

参数：
	@pID	int	仓库ID

返回：
	Table
*/
CREATE  FUNCTION [storage].[fnGetStorehouseName] (
	@pID int
)  
RETURNS
	@rt table(StorehouseID int,HouseName varchar(50),OrderNums int)
AS  
BEGIN 
	declare @ID int
	declare @Name varchar(50)
	declare @OrderNums int
	declare @TmpTable table(StorehouseID int,HouseName varchar(50),OrderNums int)

	set @OrderNums = 0
	select @ID = @pID
	if(@ID != 0)	--不为根的情况
	begin
		insert into @TmpTable select StorehouseID,HouseName,@OrderNums from tStoreHouse where StorehouseID = @ID
		while(@ID!=0)
		begin
			select @ID = ParenthouseID from tStoreHouse where StorehouseID = @ID
			set @OrderNums = @OrderNums + 1
			if(@ID = 0 or @ID is null) break

			insert into @TmpTable
			select StorehouseID,HouseName,@OrderNums from tStoreHouse where StorehouseID = @ID
		end
	end

	--insert into @TmpTable values(0,'根类',@OrderNums)

	insert into @rt
	select * from @TmpTable order by OrderNums desc
	return

END



GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取出库类别（0-正常出库 1-退货出库 2-盘亏出库）。
参数：
	@pTakeoutType	出库类别
返回：
	文字描述
*/
CREATE FUNCTION [storage].[fnGetTakeoutTypeName]
 (
	@pTakeoutType as int
)  
RETURNS varchar(100) AS  
BEGIN 
	declare @sName as varchar(100)
	set @sName = case @pTakeoutType when 0 then '正常出库' when 1 then '<font color=red>退货出库</font>' when 2 then '<font color=green>盘亏出库</font>'  when 3 then '<font color=Orange>调拨出库</font>' end

	return @sName
END


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：根据给定的根类区域ID，将其子类的区域信息以Table的方式输出

输入参数：       @pParentAreaID=根类地区ID
		@pDepthlength=进入几级进深		若不需要设置进深度则@pDepthlength=0
		@pCurlength=当前进深等级		使用时，此值始终输入0


结果：以Table 方式输出
*/
CREATE FUNCTION [storage].[fnGetTreeAreaTable] (@pParentAreaID int,@pDepthlength int ,@pCurlength int =0)  
RETURNS 
@pRetTable	Table(AreaID numeric(18,0),ParentAreaID numeric(18,0),AreaName varchar(20))
AS  
BEGIN 


	--select dbo.fnGetClassStr(1,2)
	--下面是对分类的递归分类串进行拆分，然后根据每个ID值，将对应的信息插入到TABLE中，然后返回出去
	declare @pStart int
	declare @pAreaID varchar(20)
	declare @pAreaList varchar(200)
	declare @pTmpTable Table(AreaID numeric(18,0),ParentAreaID numeric(18,0),AreaName varchar(20))

	set @pAreaList=storage.fnGetAreaClassStr(@pParentAreaID,@pDepthlength,@pCurlength) --获取递归的串，以字符串将子类集返回，多个分类用逗号分隔

	set @pStart=charindex(',',@pAreaList)

	while(@pStart>0)
	begin
		set @pAreaID=left(@pAreaList,@pStart-1)
		Insert into @pTmpTable select	AreaID,ParentAreaID,AreaName from tArea where AreaID=@pAreaID
		set @pAreaList=right(@pAreaList,len(@pAreaList)-@pStart)
		set @pStart=charindex(',',@pAreaList)
	end

	if(@pAreaList!='')
	BEGIN
		set @pAreaID=@pAreaList
		Insert into @pTmpTable select	AreaID,ParentAreaID,AreaName from tArea where AreaID=@pAreaID
	END

	Insert into @pRetTable select * from @pTmpTable order by AreaID asc
	
return
END




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：根据给定的根类库房ID，将其子类的库房信息以Table的方式输出

输入参数：       @pParentHouseID=根类地区ID
		@pDepthlength=进入几级进深		若不需要设置进深度则@pDepthlength=0
		@pCurlength=当前进深等级		使用时，此值始终输入0


结果：以Table 方式输出
*/
CREATE FUNCTION [storage].[fnGetTreeStorageHouseTable] (@pParentHouseID int,@pDepthlength int ,@pCurlength int =0)  
RETURNS 
@pRetTable	Table(StoreHouseID numeric(18,0),ParentHouseID numeric(18,0),HouseName varchar(20))
AS  
BEGIN 


	--select dbo.fnGetClassStr(1,2)
	--下面是对分类的递归分类串进行拆分，然后根据每个ID值，将对应的信息插入到TABLE中，然后返回出去
	declare @pStart int
	declare @pStoreHouseID varchar(20)
	declare @pStoreHouseIDList varchar(200)
	declare @pTmpTable Table(StoreHouseID numeric(18,0),ParentHouseID numeric(18,0),HouseName varchar(20))

	set @pStoreHouseIDList=storage.fnGetStorageHouseClassStr(@pParentHouseID,@pDepthlength,@pCurlength) --获取递归的串，以字符串将子类集返回，多个分类用逗号分隔

	set @pStart=charindex(',',@pStoreHouseIDList)

	while(@pStart>0)
	begin
		set @pStoreHouseID=left(@pStoreHouseIDList,@pStart-1)
		Insert into @pTmpTable select	StoreHouseID,ParentHouseID,HouseName from tStoreHouse where StoreHouseID=@pStoreHouseID
		set @pStoreHouseIDList=right(@pStoreHouseIDList,len(@pStoreHouseIDList)-@pStart)
		set @pStart=charindex(',',@pStoreHouseIDList)
	end

	if(@pStoreHouseIDList!='')
	BEGIN
		set @pStoreHouseID=@pStoreHouseIDList
		Insert into @pTmpTable select	StoreHouseID,ParentHouseID,HouseName from tStoreHouse where StoreHouseID=@pStoreHouseID
	END

	Insert into @pRetTable select * from @pTmpTable order by StoreHouseID asc
	
return
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	获取某计量单位的所有转换单位组成的字串。
参数：
	@UnitID	计量单位ID
返回：
	转换计量单位组成的字串。
	如：=10件=500个
*/
CREATE FUNCTION [storage].[fnUnitConversion] (@UnitID as int)  
RETURNS varchar(100) AS  
BEGIN 
	declare @Nums as varchar(100)
	set @Nums=''

	select
		 @Nums=@Nums+'='+convert(varchar(10),Nums)+u.UnitName
	 from 
		tUnitConversion c,tUnit u
	 where 
		c.UnitID=@UnitID and u.UnitID=c.ConvUnitID and c.GoodID is null

	return @Nums
END







GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE TABLE [dbo].[tAfterService] (
	[ServiceID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[Title] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[ServiceDate] [datetime] NOT NULL ,
	[Content] [varchar] (500) COLLATE Chinese_PRC_CI_AS NULL ,
	[Operator] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[WriteMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[WriteTime] [datetime] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tArea] (
	[AreaID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentAreaID] [numeric](18, 0) NULL ,
	[AreaName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBaseData] (
	[DataID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[DataValue] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Enabled] [tinyint] NOT NULL ,
	[DataType] [tinyint] NOT NULL ,
	[GoodsID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBaseDataTree] (
	[DataID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentDataID] [numeric](18, 0) NULL ,
	[DataValue] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[DataType] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfBuy] (
	[BillOfBuyID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[BuyDate] [datetime] NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[CustomerName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[Tel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[ApplyTime] [datetime] NULL ,
	[BuyReason] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[LinkMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ApplyPerson] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[GiveDate] [datetime] NULL ,
	[AllMoney] [numeric](12, 2) NULL ,
	[FactAllMoney] [numeric](12, 2) NULL ,
	[CountAllMoney] [numeric](12, 2) NULL ,
	[UpfrontMoney] [numeric](12, 2) NULL ,
	[FactoryDeputy] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Discount] [numeric](5, 2) NULL ,
	[Status] [tinyint] NOT NULL ,
	[WriteTime] [datetime] NOT NULL ,
	[WriteMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[OrderType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[PayMoney] [numeric](12, 2) NULL ,
	[NoPayMoney] [numeric](12, 2) NULL ,
	[IsPayAllMoney] [tinyint] NOT NULL ,
	[Payouter] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[StoreMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QcID] [numeric](18, 0) NULL ,
	[QualityMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[BuyerID] [numeric](18, 0) NULL ,
	[OrderID] [numeric](18, 0) NULL ,
	[OrderNo] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[InvoiceType] [tinyint] NULL ,
	[Memo] [text] COLLATE Chinese_PRC_CI_AS NULL ,
	[TransTypeID] [numeric](18, 0) NULL ,
	[GatheringTypeID] [numeric](18, 0) NULL ,
	[CancelStatus] [tinyint] NULL ,
	[PutInStatus] [tinyint] NULL ,
	[TakeOutStatus] [tinyint] NULL ,
	[GoodsType] [tinyint] NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfExchange] (
	[BillOfExchangeID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[FromStoreHouseID] [numeric](18, 0) NOT NULL ,
	[ToStoreHouseID] [numeric](18, 0) NOT NULL ,
	[SequenceNum] [numeric](18, 0) NOT NULL ,
	[ExchangeEmpID] [numeric](18, 0) NOT NULL ,
	[ExchangeMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[ExchangeDate] [datetime] NOT NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillDate] [datetime] NOT NULL ,
	[FromStorerID] [numeric](18, 0) NULL ,
	[FromStorer] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[ToStorerID] [numeric](18, 0) NULL ,
	[ToStorer] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[QualityMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[PutinDate] [datetime] NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[IsProcPutin] [tinyint] NOT NULL ,
	[IsProcTakeout] [tinyint] NOT NULL ,
	[BillOfPutinID] [numeric](18, 0) NULL ,
	[BillOfTakeoutID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfPutin] (
	[BillOfPutinID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[PutinEmpID] [numeric](18, 0) NULL ,
	[PutinEmpName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[PutinTime] [datetime] NOT NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillDate] [datetime] NOT NULL ,
	[StorerID] [numeric](18, 0) NOT NULL ,
	[Storer] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendWorkID] [numeric](18, 0) NULL ,
	[QcID] [numeric](18, 0) NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[PutinType] [tinyint] NOT NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[QualityMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTableID] [numeric](18, 0) NULL ,
	[VoucherNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelType] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfSell] (
	[BillOfSellID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[SellDate] [datetime] NOT NULL ,
	[CustomerName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Tel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[GatheringTypeID] [numeric](18, 0) NOT NULL ,
	[TransTypeID] [numeric](18, 0) NULL ,
	[DeptID] [numeric](18, 0) NOT NULL ,
	[SellerID] [numeric](18, 0) NOT NULL ,
	[OrderID] [numeric](18, 0) NULL ,
	[WriteMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillDate] [datetime] NOT NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckDate] [datetime] NULL ,
	[Payouter] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[StoreMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendGoodsMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendDate] [datetime] NULL ,
	[QualityMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[InvoiceType] [tinyint] NULL ,
	[GetCash] [numeric](12, 2) NOT NULL ,
	[UpfrontMoney] [numeric](12, 2) NOT NULL ,
	[Discount] [numeric](5, 2) NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[FactAllMoney] [numeric](12, 2) NOT NULL ,
	[CountAllMoney] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[CancelStatus] [tinyint] NULL ,
	[PayMoney] [numeric](12, 2) NOT NULL ,
	[NoPayMoney] [numeric](12, 2) NOT NULL ,
	[IsPayAllMoney] [tinyint] NOT NULL ,
	[PutInStatus] [tinyint] NULL ,
	[TakeOutStatus] [tinyint] NULL ,
	[CompID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfSendgoods] (
	[BillID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBillOfTakeout] (
	[BillOfTakeoutID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NULL ,
	[TakeOutEmpID] [numeric](18, 0) NULL ,
	[TakeoutEmpName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[TakeOutTime] [datetime] NOT NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillDate] [datetime] NOT NULL ,
	[StorerID] [numeric](18, 0) NOT NULL ,
	[Storer] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendWorkID] [numeric](18, 0) NULL ,
	[QcID] [numeric](18, 0) NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[TakeoutType] [tinyint] NOT NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[QualityMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTableID] [numeric](18, 0) NULL ,
	[BatchNO] [varchar] (12) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBuyApply] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[ApplyTime] [datetime] NULL ,
	[BuyReason] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[ApplyPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[TablePerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SupplierID] [numeric](18, 0) NULL ,
	[SupplierName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[GetGoodsDate] [datetime] NULL ,
	[WriteTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[TotalMoney] [numeric](12, 2) NULL ,
	[QcID] [numeric](18, 0) NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBuyApplyDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetID] [numeric](18, 0) NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[GoodsNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Goodsname] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NULL ,
	[UseNumber] [numeric](12, 2) NULL ,
	[Number] [numeric](12, 2) NULL ,
	[CurStoreNums] [numeric](12, 2) NULL ,
	[Moneys] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tBuyPay] (
	[PayID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfBuyID] [numeric](18, 0) NOT NULL ,
	[PayMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayMoney] [numeric](12, 2) NOT NULL ,
	[PayTime] [datetime] NULL ,
	[RecvedMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayTypeID] [numeric](18, 0) NULL ,
	[Type] [tinyint] NOT NULL ,
	[WriteMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[WriteTime] [datetime] NOT NULL ,
	[NoRecvMoney] [numeric](12, 2) NULL ,
	[IsPayAllMoney] [tinyint] NOT NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCabinetSell] (
	[CID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CCoding] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CNum] [numeric](18, 0) NOT NULL ,
	[Type] [tinyint] NOT NULL ,
	[ExcelName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CTime] [datetime] NULL ,
	[CNumber] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCalCheckinReportData] (
	[CalCheckinID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CheckinReportID] [numeric](18, 0) NULL ,
	[SellerName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckInDate] [smalldatetime] NULL ,
	[CustomerName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[BuyNums] [numeric](18, 2) NULL ,
	[BuyPrice] [numeric](18, 2) NULL ,
	[BuyMoney] [numeric](18, 2) NULL ,
	[BatchNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCalcDetail] (
	[CalcID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[DetailID] [numeric](18, 0) NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Number] [numeric](12, 2) NULL ,
	[Fee] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCalcSheet] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ClassID] [numeric](18, 0) NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendWorkID] [numeric](18, 0) NULL ,
	[ToManFee] [numeric](12, 2) NULL ,
	[Status] [tinyint] NOT NULL ,
	[TableMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[TableDate] [datetime] NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckDate] [datetime] NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCalcSheetDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetID] [numeric](18, 0) NULL ,
	[EmpID] [numeric](18, 0) NULL ,
	[EmpName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CalcDate] [datetime] NULL ,
	[StartDate] [datetime] NULL ,
	[CompleteDate] [datetime] NULL ,
	[ManFee] [numeric](12, 2) NULL ,
	[Factor] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCalcUnit] (
	[CalcID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[GoodsCode] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Number] [numeric](12, 2) NULL ,
	[CalcFee] [numeric](12, 2) NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCheckTable] (
	[CheckTableID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[Title] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[CheckEmpID] [numeric](18, 0) NOT NULL ,
	[CheckEmpName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CheckDate] [datetime] NOT NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillDate] [datetime] NOT NULL ,
	[StorerID] [numeric](18, 0) NOT NULL ,
	[Storer] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[AuditingMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AuditingTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[IsProcFull] [tinyint] NOT NULL ,
	[IsProcLost] [tinyint] NOT NULL ,
	[BillOfPutinID] [numeric](18, 0) NULL ,
	[BillOfTakeoutID] [numeric](18, 0) NULL ,
	[BeginDate] [datetime] NOT NULL ,
	[EndDate] [datetime] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCheckTableFirst] (
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[FirstNums] [numeric](12, 2) NOT NULL ,
	[CheckDate] [datetime] NOT NULL ,
	[CheckTableID] [numeric](18, 0) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCheckinReport] (
	[CheckinReportID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CheckinDate] [smalldatetime] NULL ,
	[ProClassID] [numeric](18, 0) NULL ,
	[BeginDate] [smalldatetime] NULL ,
	[EndDate] [smalldatetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tClassDoc] (
	[ClassID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentID] [numeric](18, 0) NULL ,
	[ClassNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ClassName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ClassType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tClassDocLog] (
	[DayID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[WriteDate] [datetime] NULL ,
	[CallDate] [datetime] NULL ,
	[EmpNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Readme] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCommRakeOff] (
	[RakeOffID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Year] [int] NOT NULL ,
	[LowValue] [numeric](12, 2) NOT NULL ,
	[UpperValue] [numeric](12, 2) NOT NULL ,
	[Rate] [numeric](5, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCommYearTaskMoney] (
	[TaskID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Year] [int] NOT NULL ,
	[TotalMoney] [numeric](18, 2) NOT NULL ,
	[StartDate] [datetime] NOT NULL ,
	[EndDate] [datetime] NOT NULL ,
	[BaseRate] [numeric](5, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCompany] (
	[CompID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentCompID] [numeric](18, 0) NULL ,
	[CompTypeID] [numeric](18, 0) NOT NULL ,
	[CompNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CompName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Corporation] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CorpMobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CorpTel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel1] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel2] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Fax] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCompanyEmployee] (
	[EmpID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CompID] [numeric](18, 0) NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[EmpNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[EmpName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Sex] [varchar] (2) COLLATE Chinese_PRC_CI_AS NULL ,
	[TypeID] [numeric](18, 0) NOT NULL ,
	[ClassID] [numeric](18, 0) NULL ,
	[Birthday] [datetime] NULL ,
	[Pocility] [varchar] (5) COLLATE Chinese_PRC_CI_AS NULL ,
	[IdentyNum] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[GraduateSchool] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Mobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[HomeTel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[HealthyStatus] [varchar] (5) COLLATE Chinese_PRC_CI_AS NULL ,
	[Marrage] [tinyint] NULL ,
	[Long] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Weight] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Posts] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[eType] [tinyint] NOT NULL ,
	[Job] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[JoinDate] [datetime] NULL ,
	[LeftDate] [datetime] NULL ,
	[Photo] [varchar] (30) COLLATE Chinese_PRC_CI_AS NULL ,
	[BaseWages] [numeric](18, 0) NULL ,
	[CountWages] [numeric](18, 0) NULL ,
	[Memo] [varchar] (30) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tContract] (
	[ContractID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[ContractNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Title] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[StartDate] [datetime] NOT NULL ,
	[EndDate] [datetime] NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[Content] [text] COLLATE Chinese_PRC_CI_AS NULL ,
	[Name] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Identity] [varchar] (18) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnderwriteDate] [datetime] NOT NULL ,
	[WriteDate] [datetime] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[Adjunct1] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Adjunct2] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[SequenceNum] [int] NOT NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCostOfProduct] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CostMaterial1] [numeric](12, 2) NULL ,
	[CostMaterial2] [numeric](12, 2) NULL ,
	[CostMaterial3] [numeric](12, 2) NULL ,
	[CostMaterial] [numeric](12, 2) NULL ,
	[PayPerson] [numeric](12, 2) NULL ,
	[MakePay] [numeric](12, 2) NULL ,
	[CostTotal] [numeric](12, 2) NULL ,
	[SaleTotal] [numeric](12, 2) NULL ,
	[SaleBenifit] [numeric](12, 2) NULL ,
	[StatPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[StatTime] [datetime] NULL ,
	[SaleTime] [datetime] NULL ,
	[Checkornot] [tinyint] NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCrafRoute] (
	[CrafID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CrafNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CrafName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductID] [numeric](18, 0) NULL ,
	[ProductNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ToFee] [numeric](12, 2) NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCrafRouteDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CrafID] [numeric](18, 0) NULL ,
	[WorkNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[WorkName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[EqID] [numeric](18, 0) NULL ,
	[EqName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductFee] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[LinupTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[PreparTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[WaitTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProcessTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[Conveyancetime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[KeyWork] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCustomer] (
	[CustomerID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CustNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NULL ,
	[ShortName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AreaID] [numeric](18, 0) NOT NULL ,
	[FullName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[CompID] [numeric](18, 0) NULL ,
	[DeptID] [numeric](18, 0) NOT NULL ,
	[CustomerTypeID] [numeric](18, 0) NOT NULL ,
	[TransTypeID] [numeric](18, 0) NULL ,
	[EmpID] [numeric](18, 0) NOT NULL ,
	[Corporation] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CorpMobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[LinkMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel1] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel2] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[LinkMobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Post] [varchar] (6) COLLATE Chinese_PRC_CI_AS NULL ,
	[Fax] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[E-Mail] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Http] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendGoodsAdd] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[ContactAdd] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Bank] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[BankAccount] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[RatepayingNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CreditDays] [numeric](18, 0) NOT NULL ,
	[CreditMondy] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[IsPayRake] [tinyint] NOT NULL ,
	[Type] [tinyint] NOT NULL ,
	[CustType] [tinyint] NOT NULL ,
	[DelFlag] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCustomerPay] (
	[PayID] [int] IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[CountAllMoney] [numeric](12, 2) NOT NULL ,
	[PayMoney] [numeric](12, 2) NOT NULL ,
	[BackMoney] [numeric](12, 2) NOT NULL ,
	[ReturnMoney] [numeric](12, 2) NOT NULL ,
	[Status] [tinyint] NOT NULL ,
	[SellAllDate] [datetime] NULL ,
	[TuneMoney] [numeric](12, 2) NOT NULL ,
	[KeepMoney] [numeric](12, 2) NOT NULL ,
	[CheckMoney] [numeric](12, 2) NOT NULL ,
	[AcceptMoney] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCustomerProductPrice] (
	[PriceID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[Price] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tCustomerRelation] (
	[RelationID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CheckinReportID] [numeric](18, 0) NULL ,
	[RootCustomerID] [numeric](18, 0) NULL ,
	[SubCustomerID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDepartment] (
	[DeptID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentDeptID] [numeric](18, 0) NULL ,
	[CompID] [numeric](18, 0) NOT NULL ,
	[DeptNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[DeptName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[principal] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfBuy] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfBuyID] [numeric](18, 0) NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnitID] [numeric](18, 0) NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[procType] [int] NULL ,
	[BuyDate] [datetime] NULL ,
	[UseNumber] [numeric](12, 2) NULL ,
	[Nums] [numeric](12, 2) NULL ,
	[CurStoreNums] [numeric](12, 2) NULL ,
	[Price] [numeric](12, 2) NULL ,
	[SubMoney] [numeric](12, 2) NULL ,
	[Rate] [numeric](5, 2) NOT NULL ,
	[FactMoney] [numeric](12, 2) NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[CancelNums] [numeric](18, 0) NULL ,
	[CancelDate] [datetime] NULL ,
	[CancelReason] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelMoney] [numeric](12, 2) NULL ,
	[IsPayCancelMoney] [tinyint] NULL ,
	[BackBillID] [numeric](18, 0) NULL ,
	[PutInBillID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfCheckCount] (
	[CheckTableID] [numeric](18, 0) NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[FirstNums] [numeric](12, 2) NOT NULL ,
	[PutinNums] [numeric](12, 2) NOT NULL ,
	[TakeoutNums] [numeric](12, 2) NOT NULL ,
	[BackNumsFromCustomer] [numeric](12, 2) NOT NULL ,
	[BackNumsToProvider] [numeric](12, 2) NOT NULL ,
	[LastNums] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfCheckTable] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CheckTableID] [numeric](18, 0) NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[SysNums] [numeric](12, 2) NOT NULL ,
	[FactNums] [numeric](12, 2) NOT NULL ,
	[DisNums] [numeric](12, 2) NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[DisMoney] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckDate] [datetime] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfExchange] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfExchangeID] [numeric](18, 0) NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[ExchangeNums] [numeric](12, 2) NOT NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[Status] [tinyint] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[BatchNO] [varchar] (12) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfOrder] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[OrderID] [numeric](18, 0) NULL ,
	[ProcID] [numeric](18, 0) NOT NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProcType] [int] NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Nums] [numeric](12, 2) NOT NULL ,
	[UnitID] [numeric](18, 0) NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[BuyPrice] [numeric](12, 2) NOT NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[Rate] [numeric](5, 2) NULL ,
	[SubMoney] [numeric](12, 2) NOT NULL ,
	[FactMoney] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfPutin] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfPutinID] [numeric](18, 0) NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[PutinNums] [numeric](12, 2) NOT NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[CurStoreNums] [numeric](18, 0) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[PutinType] [tinyint] NOT NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PutinTime] [datetime] NOT NULL ,
	[UsedNums] [numeric](12, 2) NOT NULL ,
	[HasNums] [numeric](12, 2) NOT NULL ,
	[Status] [tinyint] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[MadeDate] [datetime] NOT NULL ,
	[StoreDays] [int] NOT NULL ,
	[BatchNO] [varchar] (12) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfSell] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfSellID] [numeric](18, 0) NULL ,
	[ProcID] [numeric](18, 0) NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[UnitID] [numeric](18, 0) NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[procType] [int] NULL ,
	[SellDate] [datetime] NULL ,
	[Nums] [numeric](12, 2) NOT NULL ,
	[BuyPrice] [numeric](12, 2) NOT NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[SubMoney] [numeric](12, 2) NOT NULL ,
	[Rate] [numeric](5, 2) NOT NULL ,
	[FactMoney] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[CancelNums] [numeric](12, 2) NOT NULL ,
	[CancelDate] [datetime] NULL ,
	[CancelReason] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelMoney] [numeric](12, 2) NOT NULL ,
	[IsPayCancelMoney] [tinyint] NOT NULL ,
	[BackBillID] [numeric](18, 0) NULL ,
	[TakeOutBillID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfSellBack] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SellBackID] [numeric](18, 0) NOT NULL ,
	[ProcID] [numeric](18, 0) NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProcType] [int] NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelNums] [numeric](12, 2) NULL ,
	[CancelDate] [datetime] NULL ,
	[CancelMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnitID] [numeric](18, 0) NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CancelMoney] [numeric](12, 2) NULL ,
	[Price] [numeric](12, 2) NULL ,
	[Rate] [numeric](5, 2) NULL ,
	[CancelReason] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NULL ,
	[BackBillID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfSellReport] (
	[ListID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ReportID] [numeric](18, 0) NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[FirstMoney] [numeric](12, 2) NOT NULL ,
	[SellMoney] [numeric](12, 2) NOT NULL ,
	[BackMoney] [numeric](12, 2) NOT NULL ,
	[AdjustMoney] [numeric](12, 2) NOT NULL ,
	[RakeoffMoney] [numeric](12, 2) NOT NULL ,
	[OtherMoney] [numeric](12, 2) NOT NULL ,
	[GetMoney] [numeric](12, 2) NOT NULL ,
	[TransMoney] [numeric](12, 2) NOT NULL ,
	[LastMoney] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[EmpID] [numeric](18, 0) NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[Num] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[FullName] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfTakeout] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfTakeoutID] [numeric](18, 0) NOT NULL ,
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NOT NULL ,
	[OutNums] [numeric](12, 2) NOT NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[CurStoreNums] [numeric](18, 0) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[TakeoutType] [tinyint] NOT NULL ,
	[TakeoutTime] [datetime] NOT NULL ,
	[Status] [tinyint] NOT NULL ,
	[Memo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[BatchNO] [varchar] (12) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDetailOfTakeoutSource] (
	[DetailID] [numeric](18, 0) NOT NULL ,
	[DetailIDOfPutin] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[Nums] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[BatchNO] [varchar] (12) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDocMain] (
	[DocID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[DocNo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Title] [varchar] (200) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Object] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[ObjSend] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[CSend] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[Description] [text] COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[sType] [tinyint] NOT NULL ,
	[DocUrl] [varchar] (500) COLLATE Chinese_PRC_CI_AS NULL ,
	[CompID] [numeric](18, 0) NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[EmpID] [numeric](18, 0) NOT NULL ,
	[SendNo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[SendName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[WriteTime] [datetime] NULL ,
	[SendTime] [datetime] NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDocRS] (
	[RevID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[DocID] [numeric](18, 0) NOT NULL ,
	[CompID] [numeric](18, 0) NOT NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[EmpID] [numeric](18, 0) NULL ,
	[RevName] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[RevDepName] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[RevTime] [datetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tDocType] (
	[DocHeadID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CompID] [numeric](18, 0) NOT NULL ,
	[DocHeadName] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Status] [tinyint] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tEmployee] (
	[EmpID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[cEmpID] [numeric](18, 0) NULL ,
	[CompID] [numeric](18, 0) NOT NULL ,
	[DeptID] [numeric](18, 0) NOT NULL ,
	[EmpNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[EmpName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Account] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Password] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Sex] [varchar] (2) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Birthday] [datetime] NULL ,
	[Mobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[HomeTel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Post] [varchar] (6) COLLATE Chinese_PRC_CI_AS NULL ,
	[Type] [tinyint] NOT NULL ,
	[EnabledFlag] [tinyint] NOT NULL ,
	[Job] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[JoinDate] [datetime] NULL ,
	[LeftDate] [datetime] NULL ,
	[Photo] [varchar] (30) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tEquipmentsDoc] (
	[EqID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[EqNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[EqName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[EqType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[tType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[AddWay] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[UseStatus] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Place] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[sValue] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[UseMonth] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProUnit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProAbility] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tGetMaterial] (
	[BillOfTakeoutID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[MakeBillDate] [datetime] NULL ,
	[AllMoney] [numeric](12, 2) NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[TakeoutType] [tinyint] NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Status] [tinyint] NULL ,
	[SendWorkID] [numeric](18, 0) NULL ,
	[OutID] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tGetMaterialDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfTakeoutID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[OutNums] [numeric](12, 2) NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AllMoney] [numeric](12, 2) NULL ,
	[CurStoreNums] [numeric](18, 0) NULL ,
	[GoodsType] [tinyint] NULL ,
	[Status] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tGoods] (
	[GoodsID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[GoodsTypeID] [numeric](18, 0) NULL ,
	[ModelID] [numeric](18, 0) NULL ,
	[SpecID] [numeric](18, 0) NULL ,
	[SequenceNum] [int] NOT NULL ,
	[GoodsCode] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Color] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnitName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[UnitID] [numeric](18, 0) NOT NULL ,
	[ProcType] [tinyint] NOT NULL ,
	[BuyPrice] [numeric](12, 2) NOT NULL ,
	[Price] [numeric](12, 2) NULL ,
	[Nums] [numeric](18, 0) NULL ,
	[Stone] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[CurStoreNums] [numeric](12, 2) NOT NULL ,
	[LowStoreCount] [numeric](12, 2) NOT NULL ,
	[UpperStoreCount] [numeric](12, 2) NOT NULL ,
	[LowSellCount] [numeric](12, 2) NOT NULL ,
	[UpperSellCount] [numeric](12, 2) NOT NULL ,
	[GoodsType] [tinyint] NOT NULL ,
	[ZoomoutPic] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[ZoominPic] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProcStatusID] [numeric](18, 0) NULL ,
	[DelFlag] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tGroupEmployee] (
	[DataID] [numeric](18, 0) NOT NULL ,
	[EmpID] [numeric](18, 0) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tKeepFee] (
	[FeeID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[UseEmpID] [numeric](18, 0) NULL ,
	[UseMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[FeeTypeID] [numeric](18, 0) NOT NULL ,
	[UseMoney] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (500) COLLATE Chinese_PRC_CI_AS NULL ,
	[UseDate] [datetime] NOT NULL ,
	[States] [tinyint] NOT NULL ,
	[PayType] [numeric](18, 0) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tMenu] (
	[MenuID] [int] IDENTITY (1, 1) NOT NULL ,
	[PMenuID] [int] NULL ,
	[MenuName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[PMenuName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[URL] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Stauts] [tinyint] NOT NULL ,
	[OrderNums] [int] NOT NULL ,
	[UrlDescribe] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tMenuOfPerson] (
	[MenuID] [int] NOT NULL ,
	[EmpID] [numeric](18, 0) NOT NULL ,
	[OrderNums] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tModel] (
	[ModelID] [int] NOT NULL ,
	[PModelID] [int] NULL ,
	[OrderNums] [int] NOT NULL ,
	[ModelName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[PModelName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[URL] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[UrlDescribe] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tOrder] (
	[OrderID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[OrderNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SequenceNum] [int] NOT NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[TransTypeID] [numeric](18, 0) NULL ,
	[SellerID] [numeric](18, 0) NULL ,
	[CustomerName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[LinkMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Mobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[BuyDate] [datetime] NOT NULL ,
	[GiveDate] [datetime] NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL ,
	[UpfrontMoney] [numeric](12, 2) NOT NULL ,
	[FactoryDeputy] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[WriteTime] [datetime] NOT NULL ,
	[WriteMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[OrderType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Processed] [int] NULL ,
	[Memo] [text] COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tPayRakeOff] (
	[RakeOffID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[Year] [int] NOT NULL ,
	[StartDate] [datetime] NULL ,
	[EndDate] [datetime] NULL ,
	[BaseMoney] [numeric](18, 2) NOT NULL ,
	[SellMoney] [numeric](12, 2) NOT NULL ,
	[Rate] [numeric](5, 2) NOT NULL ,
	[RakeoffMoney] [numeric](12, 2) NOT NULL ,
	[PayMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Payate] [datetime] NOT NULL ,
	[GetMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayGoods] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayType] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductInstall] (
	[InsID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductID] [numeric](18, 0) NOT NULL ,
	[ProductNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Number] [numeric](12, 2) NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductInstallDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[InsID] [numeric](18, 0) NULL ,
	[ProductID] [numeric](18, 0) NOT NULL ,
	[SourceNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SourceName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Number] [numeric](12, 2) NULL ,
	[GoodsType] [tinyint] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductMainPlan] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PlanType] [tinyint] NOT NULL ,
	[PlanDate] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[pNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[TableMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[RecordTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckDate] [datetime] NULL ,
	[TotalMoney] [numeric](12, 2) NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductMainPlanDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetID] [numeric](18, 0) NULL ,
	[GoodsID] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsCode] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[GoodsName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NULL ,
	[pNumber] [numeric](12, 2) NULL ,
	[fNumber] [numeric](12, 2) NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Moneys] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductPlan] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[OrderIDs] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[StartWorkTime] [datetime] NULL ,
	[FinishWorkTime] [datetime] NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CreatTablePerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[RecordTime] [datetime] NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckDate] [datetime] NULL ,
	[TotalMoney] [numeric](12, 2) NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductPlanDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetID] [numeric](18, 0) NULL ,
	[ProID] [numeric](18, 0) NULL ,
	[ProductNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NULL ,
	[Number] [int] NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[Moneys] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductPrice] (
	[PriceID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ProcID] [numeric](18, 0) NOT NULL ,
	[SubProcID] [numeric](18, 0) NOT NULL ,
	[SubNums] [numeric](18, 0) NULL ,
	[SubPrice] [numeric](12, 2) NOT NULL ,
	[UnitID] [int] NOT NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductQCRecDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ProjectID] [numeric](18, 0) NULL ,
	[RecordID] [numeric](18, 0) NULL ,
	[QCProject] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QCStandard] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[QCResult] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Result] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductQCRecord] (
	[RecordID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Supplyer] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QCType] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QcBasis] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[pNO] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[QcSheetID] [numeric](18, 0) NULL ,
	[SelectPlace] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SelectBase] [numeric](18, 0) NULL ,
	[SelectNumber] [numeric](12, 2) NULL ,
	[SelectDate] [datetime] NULL ,
	[Grade] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QCResult] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[AlreadyCheck] [tinyint] NOT NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[QCPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[QCTime] [datetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductStatusPrice] (
	[ProcID] [numeric](18, 0) NOT NULL ,
	[ProcStatusID] [numeric](18, 0) NOT NULL ,
	[Price] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tProductStoreNums] (
	[StoreHouseID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[CurStoreNums] [numeric](12, 2) NOT NULL ,
	[AllMoney] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tQuantityCheckstandard] (
	[ProjectID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentID] [numeric](18, 0) NULL ,
	[GoodsTypeID] [numeric](18, 0) NULL ,
	[CheckProject] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckStandard] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tRakeOff] (
	[RakeOffID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Year] [int] NOT NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[LowValue] [numeric](12, 2) NOT NULL ,
	[UpperValue] [numeric](12, 2) NOT NULL ,
	[Rate] [numeric](5, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tRakeOffGoods] (
	[BillID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[RakeOffID] [numeric](18, 0) NULL ,
	[Goods] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tRakeOffProduct] (
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[GoodsID] [numeric](18, 0) NOT NULL ,
	[Rate] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tReInfo] (
	[ReID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[DocID] [numeric](18, 0) NULL ,
	[EmpNo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[RePersonName] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[DepNo] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[ReDepName] [varchar] (200) COLLATE Chinese_PRC_CI_AS NULL ,
	[Content] [text] COLLATE Chinese_PRC_CI_AS NULL ,
	[Attach] [varchar] (500) COLLATE Chinese_PRC_CI_AS NULL ,
	[ReTime] [datetime] NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tRightList] (
	[ModelID] [int] NOT NULL ,
	[ObjID] [numeric](18, 0) NOT NULL ,
	[ObjType] [tinyint] NOT NULL ,
	[Operator] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[Range] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSMSCustomer] (
	[BillID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SmsID] [numeric](18, 0) NOT NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[Mobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SuccessFlag] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSellBack] (
	[SellBackID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SellBackNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SequenceNum] [int] NOT NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[CustomerName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[LinkMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Tel] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Mobile] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[SellBackDate] [datetime] NULL ,
	[AllMoney] [numeric](12, 2) NULL ,
	[UpfrontMoney] [numeric](18, 0) NULL ,
	[FactoryDeputy] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NULL ,
	[WriteTime] [datetime] NULL ,
	[WriteMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[Memo] [text] COLLATE Chinese_PRC_CI_AS NULL ,
	[CompID] [numeric](18, 0) NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSellPay] (
	[PayID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[BillOfSellID] [numeric](18, 0) NULL ,
	[PayMan] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayMoney] [numeric](12, 2) NOT NULL ,
	[PayTime] [datetime] NULL ,
	[RecvedMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (100) COLLATE Chinese_PRC_CI_AS NULL ,
	[PayTypeID] [numeric](18, 0) NULL ,
	[Type] [tinyint] NOT NULL ,
	[WriteMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[WriteTime] [datetime] NOT NULL ,
	[Status] [tinyint] NULL ,
	[CheckMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckTime] [datetime] NULL ,
	[CustomerID] [numeric](18, 0) NULL ,
	[CPayID] [int] NULL ,
	[BillID] [tinyint] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSellReport] (
	[ReportID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Title] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[BeginDate] [datetime] NOT NULL ,
	[EndDate] [datetime] NOT NULL ,
	[EmployeeID] [numeric](18, 0) NULL ,
	[AreaID] [numeric](18, 0) NULL ,
	[MakeBillMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[MakeBillDate] [datetime] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSellReportFirst] (
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[FirstMoney] [numeric](12, 2) NOT NULL ,
	[ReportDate] [datetime] NOT NULL ,
	[ReportID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSendWorker] (
	[SheetID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[PlanID] [numeric](18, 0) NULL ,
	[RecordTime] [datetime] NULL ,
	[StartTime] [datetime] NULL ,
	[FinishTime] [datetime] NULL ,
	[TablePerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[SuperPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[DeptID] [numeric](18, 0) NULL ,
	[ClassID] [numeric](18, 0) NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [tinyint] NOT NULL ,
	[CheckPerson] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[CheckDate] [datetime] NULL ,
	[TotalMoney] [numeric](12, 2) NULL ,
	[QcID] [numeric](18, 0) NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSendWorkerDetail] (
	[DetailID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[SheetID] [numeric](18, 0) NULL ,
	[ProductID] [numeric](18, 0) NULL ,
	[ProductNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProductName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Spec] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Model] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Unit] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Price] [numeric](12, 2) NULL ,
	[Number] [numeric](12, 2) NULL ,
	[PNO] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Moneys] [numeric](12, 2) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSheetCode] (
	[CodeID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Code] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[CompID] [numeric](18, 0) NOT NULL ,
	[SheetType] [tinyint] NOT NULL ,
	[SheetName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSms] (
	[SmsID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Content] [varchar] (100) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[SubmitTime] [datetime] NOT NULL ,
	[Status] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tStoreHouse] (
	[StoreHouseID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[ParentHouseID] [numeric](18, 0) NULL ,
	[HouseName] [varchar] (20) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[DutyMan] [varchar] (20) COLLATE Chinese_PRC_CI_AS NULL ,
	[AreaNums] [numeric](12, 2) NOT NULL ,
	[Memo] [varchar] (500) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tSubProcStatusPrice] (
	[ProcID] [numeric](18, 0) NOT NULL ,
	[SubProcID] [numeric](18, 0) NOT NULL ,
	[ProcStatusID] [numeric](18, 0) NOT NULL ,
	[Price] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tTakeoutForm] (
	[TakeoutDetailID] [numeric](18, 0) NOT NULL ,
	[PutinDetailID] [numeric](18, 0) NOT NULL ,
	[UseNums] [numeric](12, 2) NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tTest] (
	[c1] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[c2] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[c3] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[c4] [numeric](12, 2) NOT NULL ,
	[c5] [numeric](12, 2) NOT NULL ,
	[c6] [numeric](12, 2) NOT NULL ,
	[c7] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[c8] [varchar] (50) COLLATE Chinese_PRC_CI_AS NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tUnit] (
	[UnitID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[UnitName] [varchar] (10) COLLATE Chinese_PRC_CI_AS NOT NULL ,
	[GoodsType] [tinyint] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tUnitConversion] (
	[ConvID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[UnitID] [numeric](18, 0) NOT NULL ,
	[ConvUnitID] [numeric](18, 0) NOT NULL ,
	[Nums] [numeric](18, 0) NOT NULL ,
	[GoodID] [numeric](18, 0) NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tWorkpreface] (
	[WorkID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[WorkNo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[WorkName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[WorkCenter] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[LineupTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[PreparTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[WaitTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[ProcessTime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[Conveyancetime] [varchar] (10) COLLATE Chinese_PRC_CI_AS NULL ,
	[Keywork] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[EqID] [numeric](18, 0) NULL ,
	[EqName] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Status] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL ,
	[Memo] [varchar] (50) COLLATE Chinese_PRC_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[tYearTaskMoney] (
	[TaskID] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[Year] [int] NOT NULL ,
	[CustomerID] [numeric](18, 0) NOT NULL ,
	[TotalMoney] [numeric](18, 2) NOT NULL ,
	[BaseRate] [numeric](5, 2) NOT NULL ,
	[StartDate] [datetime] NOT NULL ,
	[EndDate] [datetime] NOT NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tAfterService] WITH NOCHECK ADD 
	CONSTRAINT [PK_TAFTERSERVICE] PRIMARY KEY  CLUSTERED 
	(
		[ServiceID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tArea] WITH NOCHECK ADD 
	CONSTRAINT [PK_TAREA] PRIMARY KEY  CLUSTERED 
	(
		[AreaID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBaseData] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBASEDATA] PRIMARY KEY  CLUSTERED 
	(
		[DataID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBaseDataTree] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBASEDATATREE] PRIMARY KEY  CLUSTERED 
	(
		[DataID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfBuy] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFBUY] PRIMARY KEY  CLUSTERED 
	(
		[BillOfBuyID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfExchange] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFEXCHANGE] PRIMARY KEY  CLUSTERED 
	(
		[BillOfExchangeID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfPutin] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFPUTIN] PRIMARY KEY  CLUSTERED 
	(
		[BillOfPutinID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfSell] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFSELL] PRIMARY KEY  CLUSTERED 
	(
		[BillOfSellID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfSendgoods] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFSENDGOODS] PRIMARY KEY  CLUSTERED 
	(
		[BillID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBillOfTakeout] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBILLOFTAKEOUT] PRIMARY KEY  CLUSTERED 
	(
		[BillOfTakeoutID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBuyApply] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBUYAPPLY] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBuyApplyDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBUYAPPLYDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tBuyPay] WITH NOCHECK ADD 
	CONSTRAINT [PK_TBUYPAY] PRIMARY KEY  CLUSTERED 
	(
		[PayID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCabinetSell] WITH NOCHECK ADD 
	CONSTRAINT [PK_tCabinetSell] PRIMARY KEY  CLUSTERED 
	(
		[CID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCalCheckinReportData] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCalCheckinProData] PRIMARY KEY  CLUSTERED 
	(
		[CalCheckinID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCalcDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCALCDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[CalcID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCalcSheet] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCALCSHEET] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCalcSheetDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCALCSHEETDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCalcUnit] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCALCUNIT] PRIMARY KEY  CLUSTERED 
	(
		[CalcID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCheckTable] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCHECKTABLE] PRIMARY KEY  CLUSTERED 
	(
		[CheckTableID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCheckinReport] WITH NOCHECK ADD 
	CONSTRAINT [PK_tCheckinReport] PRIMARY KEY  CLUSTERED 
	(
		[CheckinReportID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tClassDoc] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCLASSDOC] PRIMARY KEY  CLUSTERED 
	(
		[ClassID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tClassDocLog] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCLASSDOCLOG] PRIMARY KEY  CLUSTERED 
	(
		[DayID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCommRakeOff] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCOMMRAKEOFF] PRIMARY KEY  CLUSTERED 
	(
		[RakeOffID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCommYearTaskMoney] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCOMMYEARTASKMONEY] PRIMARY KEY  CLUSTERED 
	(
		[TaskID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCompany] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCOMPANY] PRIMARY KEY  CLUSTERED 
	(
		[CompID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCompanyEmployee] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCOMPANYEMPLOYEE] PRIMARY KEY  CLUSTERED 
	(
		[EmpID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tContract] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCONTRACT] PRIMARY KEY  CLUSTERED 
	(
		[ContractID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCostOfProduct] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCOSTOFPRODUCT] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCrafRoute] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCRAFROUTE] PRIMARY KEY  CLUSTERED 
	(
		[CrafID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCrafRouteDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCRAFROUTEDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCustomer] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCUSTOMER] PRIMARY KEY  CLUSTERED 
	(
		[CustomerID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCustomerPay] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCUSTOMERPAY] PRIMARY KEY  CLUSTERED 
	(
		[PayID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCustomerProductPrice] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCUSTOMERPRODUCTPRICE] PRIMARY KEY  CLUSTERED 
	(
		[PriceID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tCustomerRelation] WITH NOCHECK ADD 
	CONSTRAINT [PK_TCustomerRelation] PRIMARY KEY  CLUSTERED 
	(
		[RelationID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDepartment] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDEPARTMENT] PRIMARY KEY  CLUSTERED 
	(
		[DeptID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfBuy] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFBUY] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfCheckTable] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFCHECKTABLE] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfExchange] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFEXCHANGE] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfOrder] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFORDER] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfPutin] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFPUTIN] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfSell] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFSELL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfSellBack] WITH NOCHECK ADD 
	CONSTRAINT [PK_tblDetailOfSellBack] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfSellReport] WITH NOCHECK ADD 
	CONSTRAINT [PK_tDetailOfSellReport] PRIMARY KEY  CLUSTERED 
	(
		[ListID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDetailOfTakeout] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDETAILOFTAKEOUT] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDocMain] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDOCMAIN] PRIMARY KEY  CLUSTERED 
	(
		[DocID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDocRS] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDOCRS] PRIMARY KEY  CLUSTERED 
	(
		[RevID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tDocType] WITH NOCHECK ADD 
	CONSTRAINT [PK_TDOCTYPE] PRIMARY KEY  CLUSTERED 
	(
		[DocHeadID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tEmployee] WITH NOCHECK ADD 
	CONSTRAINT [PK_TEMPLOYEE] PRIMARY KEY  CLUSTERED 
	(
		[EmpID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tEquipmentsDoc] WITH NOCHECK ADD 
	CONSTRAINT [PK_TEQUIPMENTSDOC] PRIMARY KEY  CLUSTERED 
	(
		[EqID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tGetMaterial] WITH NOCHECK ADD 
	CONSTRAINT [PK_TGETMATERIAL] PRIMARY KEY  CLUSTERED 
	(
		[BillOfTakeoutID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tGetMaterialDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TGETMATERIALDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tGoods] WITH NOCHECK ADD 
	CONSTRAINT [PK_TGOODS] PRIMARY KEY  CLUSTERED 
	(
		[GoodsID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tGroupEmployee] WITH NOCHECK ADD 
	CONSTRAINT [PK_TGROUPEMPLOYY] PRIMARY KEY  CLUSTERED 
	(
		[DataID],
		[EmpID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tKeepFee] WITH NOCHECK ADD 
	CONSTRAINT [PK_TKEEPFEE] PRIMARY KEY  CLUSTERED 
	(
		[FeeID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tMenu] WITH NOCHECK ADD 
	CONSTRAINT [PK_TMENU] PRIMARY KEY  CLUSTERED 
	(
		[MenuID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tMenuOfPerson] WITH NOCHECK ADD 
	CONSTRAINT [PK_TMENUOFPERSON] PRIMARY KEY  CLUSTERED 
	(
		[MenuID],
		[EmpID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tModel] WITH NOCHECK ADD 
	CONSTRAINT [PK_TMODEL] PRIMARY KEY  CLUSTERED 
	(
		[ModelID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tOrder] WITH NOCHECK ADD 
	CONSTRAINT [PK_TORDER] PRIMARY KEY  CLUSTERED 
	(
		[OrderID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tPayRakeOff] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPAYRAKEOFF] PRIMARY KEY  CLUSTERED 
	(
		[RakeOffID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductInstall] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTINSTALL] PRIMARY KEY  CLUSTERED 
	(
		[InsID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductInstallDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTINSTALLDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductMainPlan] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTMAINPLAN] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductMainPlanDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTMAINPLANDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductPlan] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTPLAN] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductPlanDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTPLANDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductPrice] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTPRICE] PRIMARY KEY  CLUSTERED 
	(
		[PriceID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductQCRecDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTQCRECDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductQCRecord] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTQCRECORD] PRIMARY KEY  CLUSTERED 
	(
		[RecordID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductStatusPrice] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTSTATUSPRICE] PRIMARY KEY  CLUSTERED 
	(
		[ProcID],
		[ProcStatusID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tProductStoreNums] WITH NOCHECK ADD 
	CONSTRAINT [PK_TPRODUCTSTORENUMS] PRIMARY KEY  CLUSTERED 
	(
		[StoreHouseID],
		[GoodsID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tQuantityCheckstandard] WITH NOCHECK ADD 
	CONSTRAINT [PK_TQUANTITYCHECKSTANDARD] PRIMARY KEY  CLUSTERED 
	(
		[ProjectID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tRakeOff] WITH NOCHECK ADD 
	CONSTRAINT [PK_TRAKEOFF] PRIMARY KEY  CLUSTERED 
	(
		[RakeOffID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tRakeOffGoods] WITH NOCHECK ADD 
	CONSTRAINT [PK_TRAKEOFFGOODS] PRIMARY KEY  CLUSTERED 
	(
		[BillID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tRakeOffProduct] WITH NOCHECK ADD 
	CONSTRAINT [PK_TRAKEOFFPRODUCT] PRIMARY KEY  CLUSTERED 
	(
		[CustomerID],
		[GoodsID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tReInfo] WITH NOCHECK ADD 
	CONSTRAINT [PK_TREINFO] PRIMARY KEY  CLUSTERED 
	(
		[ReID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSMSCustomer] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSMSCUSTOMER] PRIMARY KEY  CLUSTERED 
	(
		[BillID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSellBack] WITH NOCHECK ADD 
	CONSTRAINT [PK_tblSellBack] PRIMARY KEY  CLUSTERED 
	(
		[SellBackID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSellPay] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSELLPAY] PRIMARY KEY  CLUSTERED 
	(
		[PayID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSellReport] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSELLREPORT] PRIMARY KEY  CLUSTERED 
	(
		[ReportID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSendWorker] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSENDWORKER] PRIMARY KEY  CLUSTERED 
	(
		[SheetID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSendWorkerDetail] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSENDWORKERDETAIL] PRIMARY KEY  CLUSTERED 
	(
		[DetailID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSheetCode] WITH NOCHECK ADD 
	CONSTRAINT [PK_SHEETCODE] PRIMARY KEY  CLUSTERED 
	(
		[CompID],
		[SheetType]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tSms] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSMS] PRIMARY KEY  CLUSTERED 
	(
		[SmsID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tStoreHouse] WITH NOCHECK ADD 
	CONSTRAINT [PK_TSTOREHOUSE] PRIMARY KEY  CLUSTERED 
	(
		[StoreHouseID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tUnit] WITH NOCHECK ADD 
	CONSTRAINT [PK_TUNIT] PRIMARY KEY  CLUSTERED 
	(
		[UnitID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tUnitConversion] WITH NOCHECK ADD 
	CONSTRAINT [PK_TUNITCONVERSION] PRIMARY KEY  CLUSTERED 
	(
		[ConvID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tWorkpreface] WITH NOCHECK ADD 
	CONSTRAINT [PK_TWORKPREFACE] PRIMARY KEY  CLUSTERED 
	(
		[WorkID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tYearTaskMoney] WITH NOCHECK ADD 
	CONSTRAINT [PK_TYEARTASKMONEY] PRIMARY KEY  CLUSTERED 
	(
		[TaskID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[tAfterService] ADD 
	CONSTRAINT [DF__tAfterSer__Servi__0539C240] DEFAULT (getdate()) FOR [ServiceDate],
	CONSTRAINT [DF__tAfterSer__Write__062DE679] DEFAULT (getdate()) FOR [WriteTime]
GO

ALTER TABLE [dbo].[tBaseData] ADD 
	CONSTRAINT [DF__tBaseData__Enabl__0AF29B96] DEFAULT (1) FOR [Enabled],
	CONSTRAINT [DF__tBaseData__DataT__0CDAE408] DEFAULT (0) FOR [DataType],
	CONSTRAINT [CKC_ENABLED_TBASEDAT] CHECK ([Enabled] = 1 or [Enabled] = 0)
GO

ALTER TABLE [dbo].[tBaseDataTree] ADD 
	CONSTRAINT [DF__tBaseData__DataT__10AB74EC] DEFAULT (0) FOR [DataType],
	CONSTRAINT [CKC_DATATYPE_BaseTree] CHECK ([DataType] = 4 or ([DataType] = 3 or ([DataType] = 2 or ([DataType] = 1 or [DataType] = 0))))
GO

ALTER TABLE [dbo].[tBillOfBuy] ADD 
	CONSTRAINT [DF__tBillOfBu__Seque__147C05D0] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tBillOfBu__BuyDa__15702A09] DEFAULT (getdate()) FOR [BuyDate],
	CONSTRAINT [DF__tBillOfBu__AllMo__16644E42] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tBillOfBu__Upfro__1758727B] DEFAULT (0) FOR [UpfrontMoney],
	CONSTRAINT [DF_tBillOfBuy_Discount] DEFAULT (100) FOR [Discount],
	CONSTRAINT [DF__tBillOfBu__Statu__184C96B4] DEFAULT (1) FOR [Status],
	CONSTRAINT [DF__tBillOfBu__Write__1A34DF26] DEFAULT (getdate()) FOR [WriteTime],
	CONSTRAINT [DF__tBillOfBu__PayMo__1B29035F] DEFAULT (0) FOR [PayMoney],
	CONSTRAINT [DF__tBillOfBu__NoPay__1C1D2798] DEFAULT (0) FOR [NoPayMoney],
	CONSTRAINT [DF__tBillOfBu__IsPay__1D114BD1] DEFAULT (0) FOR [IsPayAllMoney],
	CONSTRAINT [DF_tBillOfBuy_InvoiceType] DEFAULT (0) FOR [InvoiceType],
	CONSTRAINT [DF_tBillOfBuy_CancelStatus] DEFAULT (0) FOR [CancelStatus],
	CONSTRAINT [DF_tBillOfBuy_PutInSign] DEFAULT (0) FOR [PutInStatus],
	CONSTRAINT [DF_tBillOfBuy_TakeOutStatus] DEFAULT (0) FOR [TakeOutStatus],
	CONSTRAINT [DF_tBillOfBuy_GoodsType] DEFAULT (0) FOR [GoodsType],
	CONSTRAINT [CKC_ISPAYALLMONEY_TBILLOFB] CHECK ([IsPayAllMoney] = 1 or [IsPayAllMoney] = 0),
	CONSTRAINT [CKC_STATUS_TBILLOFB] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tBillOfExchange] ADD 
	CONSTRAINT [DF__tBillOfEx__Seque__4ACDF4E0] DEFAULT (1) FOR [SequenceNum],
	CONSTRAINT [DF__tBillOfEx__Excha__4BC21919] DEFAULT (getdate()) FOR [ExchangeDate],
	CONSTRAINT [DF__tBillOfEx__MakeB__4CB63D52] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tBillOfEx__Goods__4DAA618B] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF_tBillOfExchange_AllMoney] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tBillOfEx__Statu__4F92A9FD] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tBillOfExchange_IsProcPutin] DEFAULT (0) FOR [IsProcPutin],
	CONSTRAINT [DF_tBillOfExchange_IsProcTakeout] DEFAULT (0) FOR [IsProcTakeout],
	CONSTRAINT [CKC_GOODSTYPE_TBILLOFE] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_STATUS_TBILLOFE] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tBillOfPutin] ADD 
	CONSTRAINT [DF__tBillOfPu__Seque__20E1DCB5] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tBillOfPu__Putin__21D600EE] DEFAULT (getdate()) FOR [PutinTime],
	CONSTRAINT [DF_tBillOfPutin_MakeBillDate] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tBillOfPu__AllMo__22CA2527] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tBillOfPu__Goods__23BE4960] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tBillOfPu__Putin__25A691D2] DEFAULT (0) FOR [PutinType],
	CONSTRAINT [DF__tBillOfPu__Statu__278EDA44] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tBillOfPutin_CancelType] DEFAULT (0) FOR [CancelType],
	CONSTRAINT [CKC_GOODSTYPE_TBILLOFP] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_PUTINTYPE_TBILLOFP] CHECK ([PutinType] = 3 or [PutinType] = 2 or ([PutinType] = 1 or [PutinType] = 0)),
	CONSTRAINT [CKC_STATUS_TBILLOFP] CHECK ([Status] = 2 or ([Status] = 1 or [Status] = 0))
GO

ALTER TABLE [dbo].[tBillOfSell] ADD 
	CONSTRAINT [DF__tBillOfSe__BillN__2B5F6B28] DEFAULT ('0') FOR [BillNO],
	CONSTRAINT [DF__tBillOfSe__Seque__2C538F61] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tBillOfSe__SellD__2D47B39A] DEFAULT (getdate()) FOR [SellDate],
	CONSTRAINT [DF__tBillOfSe__MakeB__2E3BD7D3] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tBillOfSe__Invoi__2F2FFC0C] DEFAULT (0) FOR [InvoiceType],
	CONSTRAINT [DF__tBillOfSe__GetCa__3118447E] DEFAULT (0) FOR [GetCash],
	CONSTRAINT [DF__tBillOfSe__Upfro__320C68B7] DEFAULT (0) FOR [UpfrontMoney],
	CONSTRAINT [DF__tBillOfSe__Disco__33008CF0] DEFAULT (100) FOR [Discount],
	CONSTRAINT [DF__tBillOfSe__AllMo__33F4B129] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tBillOfSe__FactA__34E8D562] DEFAULT (0) FOR [FactAllMoney],
	CONSTRAINT [DF__tBillOfSe__Count__35DCF99B] DEFAULT (0) FOR [CountAllMoney],
	CONSTRAINT [DF__tBillOfSe__Statu__36D11DD4] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tBillOfSell_CancelStatus] DEFAULT (0) FOR [CancelStatus],
	CONSTRAINT [DF__tBillOfSe__PayMo__38B96646] DEFAULT (0) FOR [PayMoney],
	CONSTRAINT [DF__tBillOfSe__NoPay__39AD8A7F] DEFAULT (0) FOR [NoPayMoney],
	CONSTRAINT [DF__tBillOfSe__IsPay__3AA1AEB8] DEFAULT (0) FOR [IsPayAllMoney],
	CONSTRAINT [DF_tBillOfSell_PutInStatus] DEFAULT (0) FOR [PutInStatus],
	CONSTRAINT [DF_tBillOfSell_TakeOutStatus] DEFAULT (0) FOR [TakeOutStatus],
	CONSTRAINT [CKC_INVOICETYPE_TBILLOFS] CHECK ([InvoiceType] is null or ([InvoiceType] = 2 or ([InvoiceType] = 1 or [InvoiceType] = 0))),
	CONSTRAINT [CKC_ISPAYALLMONEY_TBILLOFS] CHECK ([IsPayAllMoney] = 1 or [IsPayAllMoney] = 0),
	CONSTRAINT [CKC_STATUS_TBILLOFS] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tBillOfTakeout] ADD 
	CONSTRAINT [DF__tBillOfTa__Seque__405A880E] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tBillOfTa__OutTi__414EAC47] DEFAULT (getdate()) FOR [TakeOutTime],
	CONSTRAINT [DF_tBillOfTakeout_MakeBillDate] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tBillOfTa__AllMo__4242D080] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tBillOfTa__Goods__4336F4B9] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tBillOfTa__Takeo__451F3D2B] DEFAULT (0) FOR [TakeoutType],
	CONSTRAINT [DF__tBillOfTa__Statu__4707859D] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_GOODSTYPE_TBILLOFT] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_STATUS_TBILLOFT] CHECK ([Status] = 2 or ([Status] = 1 or [Status] = 0)),
	CONSTRAINT [CKC_TAKEOUTTYPE_TBILLOFT] CHECK ([TakeoutType] = 3 or [TakeoutType] = 2 or [TakeoutType] = 1 or [TakeoutType] = 0)
GO

ALTER TABLE [dbo].[tBuyApply] ADD 
	CONSTRAINT [DF__tBuyApply__Statu__2C146396] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TBUYAPPL] CHECK ([Status] = 2 or ([Status] = 1 or [Status] = 0))
GO

ALTER TABLE [dbo].[tBuyPay] ADD 
	CONSTRAINT [DF__tBuyPay__PayMone__4AD81681] DEFAULT (0) FOR [PayMoney],
	CONSTRAINT [DF__tBuyPay__PayTime__4BCC3ABA] DEFAULT (getdate()) FOR [PayTime],
	CONSTRAINT [DF_tBuyPay_PayTypeID] DEFAULT (0) FOR [PayTypeID],
	CONSTRAINT [DF__tBuyPay__Type__4CC05EF3] DEFAULT (0) FOR [Type],
	CONSTRAINT [DF__tBuyPay__WriteTi__4EA8A765] DEFAULT (getdate()) FOR [WriteTime],
	CONSTRAINT [DF__tBuyPay__NoRecvM__4F9CCB9E] DEFAULT (0) FOR [NoRecvMoney],
	CONSTRAINT [DF__tBuyPay__IsPayAl__5090EFD7] DEFAULT (0) FOR [IsPayAllMoney],
	CONSTRAINT [DF_tBuyPay_Status] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_ISPAYALLMONEY_TBUYPAY] CHECK ([IsPayAllMoney] = 1 or [IsPayAllMoney] = 0),
	CONSTRAINT [CKC_TYPE_TBUYPAY] CHECK ([Type] = 1 or [Type] = 0)
GO

ALTER TABLE [dbo].[tCabinetSell] ADD 
	CONSTRAINT [DF_tCabinetSell_CNum] DEFAULT (0) FOR [CNum],
	CONSTRAINT [DF_tCabinetSell_Type] DEFAULT (1) FOR [Type],
	CONSTRAINT [CK_tCabinetSell] CHECK ([Type] = 1 or [Type] = 2 or [Type] = 3)
GO

ALTER TABLE [dbo].[tCalCheckinReportData] ADD 
	CONSTRAINT [DF_TCalCheckinProData_CheckinReportID] DEFAULT (0) FOR [CheckinReportID],
	CONSTRAINT [DF_TCalCheckinProData_CheckInDate] DEFAULT (getdate()) FOR [CheckInDate],
	CONSTRAINT [DF_TCalCheckinProData_BuyNums] DEFAULT (0) FOR [BuyNums],
	CONSTRAINT [DF_TCalCheckinProData_BuyPrice] DEFAULT (0) FOR [BuyPrice],
	CONSTRAINT [DF_TCalCheckinProData_BuyMoney] DEFAULT (0) FOR [BuyMoney]
GO

ALTER TABLE [dbo].[tCalcSheet] ADD 
	CONSTRAINT [DF__tCalcShee__Statu__33B5855E] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TCALCSHE] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tCheckTable] ADD 
	CONSTRAINT [DF__tCheckTab__Seque__75785BC3] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tCheckTab__Check__766C7FFC] DEFAULT (getdate()) FOR [CheckDate],
	CONSTRAINT [DF_tCheckTable_MakeBillDate] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tCheckTab__AllMo__7760A435] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tCheckTab__Goods__7854C86E] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tCheckTab__Statu__7A3D10E0] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF__tCheckTab__IsPro__7C255952] DEFAULT (0) FOR [IsProcFull],
	CONSTRAINT [DF__tCheckTab__IsPro__7E0DA1C4] DEFAULT (0) FOR [IsProcLost],
	CONSTRAINT [DF_tCheckTable_BeginDate] DEFAULT (getdate()) FOR [BeginDate],
	CONSTRAINT [DF_tCheckTable_EndDate] DEFAULT (getdate()) FOR [EndDate],
	CONSTRAINT [CKC_GOODSTYPE_TCHECKTA] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_ISPROCFULL_TCHECKTA] CHECK ([IsProcFull] = 1 or [IsProcFull] = 0),
	CONSTRAINT [CKC_ISPROCLOST_TCHECKTA] CHECK ([IsProcLost] = 1 or [IsProcLost] = 0),
	CONSTRAINT [CKC_STATUS_TCHECKTA] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tCheckTableFirst] ADD 
	CONSTRAINT [DF__tCheckTab__First__79F2F81D] DEFAULT (0) FOR [FirstNums],
	CONSTRAINT [DF__tCheckTab__Check__7AE71C56] DEFAULT (getdate()) FOR [CheckDate],
	CONSTRAINT [DF__tCheckTab__Check__7BDB408F] DEFAULT (0) FOR [CheckTableID]
GO

ALTER TABLE [dbo].[tCheckinReport] ADD 
	CONSTRAINT [DF_tCheckinReport_CheckinDate] DEFAULT (getdate()) FOR [CheckinDate],
	CONSTRAINT [DF_tCheckinReport_ProClassID] DEFAULT (0) FOR [ProClassID],
	CONSTRAINT [DF_tCheckinReport_BeginDate] DEFAULT (getdate()) FOR [BeginDate],
	CONSTRAINT [DF_tCheckinReport_EndDate] DEFAULT (getdate()) FOR [EndDate]
GO

ALTER TABLE [dbo].[tCommRakeOff] ADD 
	CONSTRAINT [DF__tCommRakeO__Year__5EDF0F2E] DEFAULT (datepart(year,getdate())) FOR [Year],
	CONSTRAINT [DF__tCommRake__LowVa__5FD33367] DEFAULT (0) FOR [LowValue],
	CONSTRAINT [DF__tCommRake__Upper__60C757A0] DEFAULT (0) FOR [UpperValue],
	CONSTRAINT [DF__tCommRakeO__Rate__61BB7BD9] DEFAULT (0) FOR [Rate]
GO

ALTER TABLE [dbo].[tCommYearTaskMoney] ADD 
	CONSTRAINT [DF__tCommYearT__Year__6497E884] DEFAULT (datepart(year,getdate())) FOR [Year],
	CONSTRAINT [DF__tCommYear__Total__658C0CBD] DEFAULT (0) FOR [TotalMoney],
	CONSTRAINT [DF__tCommYear__Start__668030F6] DEFAULT (getdate()) FOR [StartDate],
	CONSTRAINT [DF__tCommYear__EndDa__6774552F] DEFAULT (getdate()) FOR [EndDate],
	CONSTRAINT [DF__tCommYear__BaseR__68687968] DEFAULT (0) FOR [BaseRate]
GO

ALTER TABLE [dbo].[tCompanyEmployee] ADD 
	CONSTRAINT [DF__tCompanyE__eType__3F27380A] DEFAULT (0) FOR [eType],
	CONSTRAINT [CKC_ETYPE_TCOMPANY] CHECK ([eType] = 2 or ([eType] = 1 or [eType] = 0))
GO

ALTER TABLE [dbo].[tContract] ADD 
	CONSTRAINT [DF__tContract__Start__6D2D2E85] DEFAULT (getdate()) FOR [StartDate],
	CONSTRAINT [DF__tContract__EndDa__6E2152BE] DEFAULT (getdate()) FOR [EndDate],
	CONSTRAINT [DF__tContract__AllMo__6F1576F7] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tContract__Under__70099B30] DEFAULT (getdate()) FOR [UnderwriteDate],
	CONSTRAINT [DF__tContract__Write__70FDBF69] DEFAULT (getdate()) FOR [WriteDate],
	CONSTRAINT [DF__tContract__Seque__71F1E3A2] DEFAULT (0) FOR [SequenceNum]
GO

ALTER TABLE [dbo].[tCustomer] ADD 
	CONSTRAINT [DF_tCustomer_SequenceNum] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tCustomer__Credi__74CE504D] DEFAULT (0) FOR [CreditDays],
	CONSTRAINT [DF__tCustomer__Credi__75C27486] DEFAULT (0) FOR [CreditMondy],
	CONSTRAINT [DF__tCustomer__IsPay__76B698BF] DEFAULT (0) FOR [IsPayRake],
	CONSTRAINT [DF__tCustomer__Type__789EE131] DEFAULT (1) FOR [Type],
	CONSTRAINT [DF_tCustomer_CustType] DEFAULT (0) FOR [CustType],
	CONSTRAINT [DF_tCustomer_DelFlag] DEFAULT (1) FOR [DelFlag],
	CONSTRAINT [CK_tCustomer] CHECK ([CustType] = 1 or [CustType] = 0),
	CONSTRAINT [CKC_ISPAYRAKE_TCUSTOME] CHECK ([IsPayRake] = 1 or [IsPayRake] = 0),
	CONSTRAINT [CKC_TYPE_TCUSTOME] CHECK ([Type] = 1 or [Type] = 0)
GO

ALTER TABLE [dbo].[tCustomerPay] ADD 
	CONSTRAINT [DF__tCustomer__Count__7192BC46] DEFAULT (0) FOR [CountAllMoney],
	CONSTRAINT [DF__tCustomer__PayMo__7286E07F] DEFAULT (0) FOR [PayMoney],
	CONSTRAINT [DF__tCustomer__BackM__737B04B8] DEFAULT (0) FOR [BackMoney],
	CONSTRAINT [DF__tCustomer__Retur__746F28F1] DEFAULT (0) FOR [ReturnMoney],
	CONSTRAINT [DF__tCustomer__Statu__75634D2A] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tCustomerPay_TuneMoney] DEFAULT (0) FOR [TuneMoney],
	CONSTRAINT [DF_tCustomerPay_KeepMoney] DEFAULT (0) FOR [KeepMoney],
	CONSTRAINT [DF_tCustomerPay_CheckMoney] DEFAULT (0) FOR [CheckMoney],
	CONSTRAINT [DF_tCustomerPay_AcceptMoney] DEFAULT (0) FOR [AcceptMoney],
	CONSTRAINT [CKC_STATUS_TCUSTOME] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tCustomerProductPrice] ADD 
	CONSTRAINT [DF__tCustomer__Price__6D031153] DEFAULT (0) FOR [Price]
GO

ALTER TABLE [dbo].[tDetailOfBuy] ADD 
	CONSTRAINT [DF__tDetailOfB__Nums__7E57BA87] DEFAULT (0) FOR [Nums],
	CONSTRAINT [DF__tDetailOf__Price__7F4BDEC0] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__SubMo__004002F9] DEFAULT (0) FOR [SubMoney],
	CONSTRAINT [DF__tDetailOfB__Rate__01342732] DEFAULT (100) FOR [Rate],
	CONSTRAINT [DF__tDetailOf__Statu__02284B6B] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tDetailOfBuy_CancelNums] DEFAULT (0) FOR [CancelNums],
	CONSTRAINT [DF_tDetailOfBuy_CancelMoney] DEFAULT (0) FOR [CancelMoney],
	CONSTRAINT [DF_tDetailOfBuy_IsPayCancelMoney] DEFAULT (0) FOR [IsPayCancelMoney],
	CONSTRAINT [CKC_STATUS_TDETAILO] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tDetailOfCheckCount] ADD 
	CONSTRAINT [DF__tDetailOf__Check__7DC38901] DEFAULT (0) FOR [CheckTableID],
	CONSTRAINT [DF__tDetailOf__First__7EB7AD3A] DEFAULT (0) FOR [FirstNums],
	CONSTRAINT [DF__tDetailOf__Putin__7FABD173] DEFAULT (0) FOR [PutinNums],
	CONSTRAINT [DF__tDetailOf__Takeo__009FF5AC] DEFAULT (0) FOR [TakeoutNums],
	CONSTRAINT [DF__tDetailOf__BackN__019419E5] DEFAULT (0) FOR [BackNumsFromCustomer],
	CONSTRAINT [DF__tDetailOf__BackN__02883E1E] DEFAULT (0) FOR [BackNumsToProvider],
	CONSTRAINT [DF__tDetailOf__LastN__037C6257] DEFAULT (0) FOR [LastNums]
GO

ALTER TABLE [dbo].[tDetailOfCheckTable] ADD 
	CONSTRAINT [DF__tDetailOf__Price__07970BFE] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__SysNu__088B3037] DEFAULT (0) FOR [SysNums],
	CONSTRAINT [DF__tDetailOf__FactN__097F5470] DEFAULT (0) FOR [FactNums],
	CONSTRAINT [DF__tDetailOf__DisNu__0A7378A9] DEFAULT (0) FOR [DisNums],
	CONSTRAINT [DF__tDetailOf__AllMo__0B679CE2] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tDetailOf__DisMo__0C5BC11B] DEFAULT (0) FOR [DisMoney],
	CONSTRAINT [DF_tDetailOfCheckTable_GoodsType] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tDetailOf__Statu__0D4FE554] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tDetailOfCheckTable_CheckDate] DEFAULT (getdate()) FOR [CheckDate],
	CONSTRAINT [CKC_STATUS_TDETAILO11] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tDetailOfExchange] ADD 
	CONSTRAINT [DF__tDetailOf__Price__5FC911C6] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__Excha__60BD35FF] DEFAULT (0) FOR [ExchangeNums],
	CONSTRAINT [DF__tDetailOf__AllMo__61B15A38] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tDetailOf__Goods__62A57E71] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tDetailOf__Statu__648DC6E3] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_GOODSTYPE_TDETAIL_Exchange] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_STATUS_TDETAIL_Exchange] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tDetailOfOrder] ADD 
	CONSTRAINT [DF_tDetailOfOrder_BuyPrice] DEFAULT (0) FOR [BuyPrice],
	CONSTRAINT [DF__tDetailOf__Price__09C96D33] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOfO__Rate__0ABD916C] DEFAULT (100) FOR [Rate],
	CONSTRAINT [DF__tDetailOf__SubMo__0BB1B5A5] DEFAULT (0) FOR [SubMoney],
	CONSTRAINT [DF__tDetailOf__Statu__0CA5D9DE] DEFAULT (1) FOR [Status],
	CONSTRAINT [CKC_STATUS_Detail] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tDetailOfPutin] ADD 
	CONSTRAINT [DF__tDetailOf__Price__10766AC2] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__Putin__116A8EFB] DEFAULT (0) FOR [PutinNums],
	CONSTRAINT [DF__tDetailOf__AllMo__125EB334] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tDetailOf__CurSt__1352D76D] DEFAULT (0) FOR [CurStoreNums],
	CONSTRAINT [DF__tDetailOf__Goods__1446FBA6] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tDetailOf__Putin__162F4418] DEFAULT (0) FOR [PutinType],
	CONSTRAINT [DF__tDetailOf__Putin__18178C8A] DEFAULT (getdate()) FOR [PutinTime],
	CONSTRAINT [DF__tDetailOf__UsedN__190BB0C3] DEFAULT (0) FOR [UsedNums],
	CONSTRAINT [DF__tDetailOf__HasNu__19FFD4FC] DEFAULT (0) FOR [HasNums],
	CONSTRAINT [DF_tDetailOfPutin_Status] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tDetailOfPutin_MadeDate] DEFAULT (getdate()) FOR [MadeDate],
	CONSTRAINT [DF_tDetailOfPutin_StoreDays] DEFAULT (1) FOR [StoreDays],
	CONSTRAINT [DF_tDetailOfPutin_BatchNO] DEFAULT (convert(varchar(12),getdate(),112)) FOR [BatchNO],
	CONSTRAINT [CKC_GOODSTYPE_TDETAILO] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)),
	CONSTRAINT [CKC_PUTINTYPE_TDETAILO] CHECK ([PutinType] = 3 or [PutinType] = 2 or ([PutinType] = 1 or [PutinType] = 0))
GO

ALTER TABLE [dbo].[tDetailOfSell] ADD 
	CONSTRAINT [DF_tDetailOfSell_SellDate] DEFAULT (getdate()) FOR [SellDate],
	CONSTRAINT [DF__tDetailOfS__Nums__1CDC41A7] DEFAULT (0) FOR [Nums],
	CONSTRAINT [DF_tDetailOfSell_BuyPrice] DEFAULT (0) FOR [BuyPrice],
	CONSTRAINT [DF__tDetailOf__Price__1DD065E0] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__SubMo__1EC48A19] DEFAULT (0) FOR [SubMoney],
	CONSTRAINT [DF__tDetailOfS__Rate__1FB8AE52] DEFAULT (100) FOR [Rate],
	CONSTRAINT [DF__tDetailOf__Statu__20ACD28B] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF__tDetailOf__Cance__22951AFD] DEFAULT (0) FOR [CancelNums],
	CONSTRAINT [DF__tDetailOf__Cance__23893F36] DEFAULT (0) FOR [CancelMoney],
	CONSTRAINT [DF__tDetailOf__IsPay__247D636F] DEFAULT (0) FOR [IsPayCancelMoney],
	CONSTRAINT [CKC_ISPAYCANCELMONEY_TDETAILO] CHECK ([IsPayCancelMoney] = 1 or [IsPayCancelMoney] = 0),
	CONSTRAINT [CKC_STATUS_DetailSell] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tDetailOfSellBack] ADD 
	CONSTRAINT [DF_tDetailOfSellBack_CancelDate] DEFAULT (getdate()) FOR [CancelDate],
	CONSTRAINT [DF_tblDetailOfSellBack_BuyPrice] DEFAULT (0) FOR [CancelMoney],
	CONSTRAINT [DF_tblDetailOfSellBack_Price] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF_tblDetailOfSellBack_Rate] DEFAULT (100) FOR [Rate],
	CONSTRAINT [DF_tblDetailOfSellBack_Status] DEFAULT (0) FOR [Status],
	CONSTRAINT [DF_tDetailOfSellBack_BackBillID] DEFAULT (0) FOR [BackBillID]
GO

ALTER TABLE [dbo].[tDetailOfSellReport] ADD 
	CONSTRAINT [DF__tDetailOf__First__10A1534B] DEFAULT (0) FOR [FirstMoney],
	CONSTRAINT [DF__tDetailOf__SellM__11957784] DEFAULT (0) FOR [SellMoney],
	CONSTRAINT [DF__tDetailOf__BackM__12899BBD] DEFAULT (0) FOR [BackMoney],
	CONSTRAINT [DF__tDetailOf__Adjus__137DBFF6] DEFAULT (0) FOR [AdjustMoney],
	CONSTRAINT [DF__tDetailOf__Rakeo__1471E42F] DEFAULT (0) FOR [RakeoffMoney],
	CONSTRAINT [DF__tDetailOf__Other__15660868] DEFAULT (0) FOR [OtherMoney],
	CONSTRAINT [DF__tDetailOf__GetMo__165A2CA1] DEFAULT (0) FOR [GetMoney],
	CONSTRAINT [DF__tDetailOf__Trans__174E50DA] DEFAULT (0) FOR [TransMoney],
	CONSTRAINT [DF__tDetailOf__LastM__18427513] DEFAULT (0) FOR [LastMoney]
GO

ALTER TABLE [dbo].[tDetailOfTakeout] ADD 
	CONSTRAINT [DF__tDetailOf__Price__284DF453] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tDetailOf__OutNu__2942188C] DEFAULT (0) FOR [OutNums],
	CONSTRAINT [DF__tDetailOf__AllMo__2A363CC5] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tDetailOf__CurSt__2B2A60FE] DEFAULT (0) FOR [CurStoreNums],
	CONSTRAINT [DF_tDetailOfTakeout_GoodsType] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tDetailOf__Takeo__2C1E8537] DEFAULT (0) FOR [TakeoutType],
	CONSTRAINT [DF__tDetailOf__Takeo__2E06CDA9] DEFAULT (getdate()) FOR [TakeoutTime],
	CONSTRAINT [DF_tDetailOfTakeout_Status] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_TAKEOUTTYPE_TDETAILO] CHECK ([TakeoutType] = 3 or [TakeoutType] = 2 or [TakeoutType] = 1 or [TakeoutType] = 0)
GO

ALTER TABLE [dbo].[tDetailOfTakeoutSource] ADD 
	CONSTRAINT [DF__tDetailOfT__Nums__50F0E28A] DEFAULT (0) FOR [Nums],
	CONSTRAINT [DF__tDetailOf__Goods__51E506C3] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF__tDetailOf__Batch__53CD4F35] DEFAULT ('convert(varchar(12),getdate(),112)') FOR [BatchNO],
	CONSTRAINT [CKC_GOODSTYPE_TDETAIL123] CHECK ([GoodsType] = 4 or [GoodsType] = 3 or [GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0))
GO

ALTER TABLE [dbo].[tDocMain] ADD 
	CONSTRAINT [DF__tDocMain__sType__7BC631F6] DEFAULT (0) FOR [sType],
	CONSTRAINT [CKC_STYPE_TDOCMAIN] CHECK ([sType] = 0 or [sType] = 1)
GO

ALTER TABLE [dbo].[tDocRS] ADD 
	CONSTRAINT [DF__tDocRS__Status__7F96C2DA] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TDOCRS] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tEmployee] ADD 
	CONSTRAINT [DF__tEmployee__Type__30E33A54] DEFAULT (1) FOR [Type],
	CONSTRAINT [DF__tEmployee__Enabl__32CB82C6] DEFAULT (1) FOR [EnabledFlag],
	CONSTRAINT [CKC_ENABLEDFLAG_TEMPLOYE] CHECK ([EnabledFlag] = 1 or [EnabledFlag] = 0),
	CONSTRAINT [CKC_TYPE_TEMPLOYE] CHECK ([Type] = 1 or [Type] = 0)
GO

ALTER TABLE [dbo].[tEquipmentsDoc] ADD 
	CONSTRAINT [DF__tEquipmen__Statu__560A9D62] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TEQUIPME] CHECK ([Status] = 4 or ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0))))
GO

ALTER TABLE [dbo].[tGetMaterial] ADD 
	CONSTRAINT [DF__tGetMater__MakeB__2B754518] DEFAULT (getdate()) FOR [MakeBillDate],
	CONSTRAINT [DF__tGetMater__AllMo__2C696951] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tGetMater__Takeo__2D5D8D8A] DEFAULT (0) FOR [TakeoutType],
	CONSTRAINT [DF__tGetMater__Statu__2F45D5FC] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TGETMATE] CHECK ([Status] is null or ([Status] = 1 or [Status] = 0)),
	CONSTRAINT [CKC_TAKEOUTTYPE_TGETMATE] CHECK ([TakeoutType] is null or ([TakeoutType] = 1 or [TakeoutType] = 0))
GO

ALTER TABLE [dbo].[tGetMaterialDetail] ADD 
	CONSTRAINT [DF__tGetMater__Price__331666E0] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF__tGetMater__OutNu__340A8B19] DEFAULT (0) FOR [OutNums],
	CONSTRAINT [DF__tGetMater__AllMo__34FEAF52] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tGetMater__CurSt__35F2D38B] DEFAULT (0) FOR [CurStoreNums],
	CONSTRAINT [DF__tGetMater__Statu__36E6F7C4] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TDETAILO2] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tGoods] ADD 
	CONSTRAINT [DF__tGoods__Sequence__369C13AA] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tGoods__ProcType__379037E3] DEFAULT (0) FOR [ProcType],
	CONSTRAINT [DF_tGoods_BuyPrice] DEFAULT (0) FOR [BuyPrice],
	CONSTRAINT [DF_tGoods_Price] DEFAULT (0) FOR [Price],
	CONSTRAINT [DF_tGoods_Nums] DEFAULT (0) FOR [Nums],
	CONSTRAINT [DF__tGoods__CurStore__39788055] DEFAULT (0) FOR [CurStoreNums],
	CONSTRAINT [DF__tGoods__LowStore__3A6CA48E] DEFAULT (0) FOR [LowStoreCount],
	CONSTRAINT [DF__tGoods__UpperSto__3B60C8C7] DEFAULT (0) FOR [UpperStoreCount],
	CONSTRAINT [DF__tGoods__LowSellC__3C54ED00] DEFAULT (0) FOR [LowSellCount],
	CONSTRAINT [DF__tGoods__UpperSel__3D491139] DEFAULT (0) FOR [UpperSellCount],
	CONSTRAINT [DF__tGoods__GoodsTyp__3E3D3572] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [DF_tGoods_DelFlag] DEFAULT (1) FOR [DelFlag],
	CONSTRAINT [CKC_GOODSTYPE_TGOODS] CHECK ([GoodsType] = 4 or ([GoodsType] = 3 or ([GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0)))),
	CONSTRAINT [CKC_PROCTYPE_TGOODS] CHECK ([ProcType] = 1 or [ProcType] = 0)
GO

ALTER TABLE [dbo].[tKeepFee] ADD 
	CONSTRAINT [DF__tKeepFee__UseMon__420DC656] DEFAULT (0) FOR [UseMoney],
	CONSTRAINT [DF__tKeepFee__UseDat__4301EA8F] DEFAULT (getdate()) FOR [UseDate],
	CONSTRAINT [DF_tKeepFee_States] DEFAULT (0) FOR [States],
	CONSTRAINT [CK_tKeepFee] CHECK ([States] = 0 or [States] = 1)
GO

ALTER TABLE [dbo].[tMenu] ADD 
	CONSTRAINT [DF__tMenu__Stauts__050FA50E] DEFAULT (0) FOR [Stauts],
	CONSTRAINT [DF_tMenu_OrderNums] DEFAULT (0) FOR [OrderNums],
	CONSTRAINT [CKC_STAUTS_TMENU] CHECK ([Stauts] = 1 or [Stauts] = 0)
GO

ALTER TABLE [dbo].[tMenuOfPerson] ADD 
	CONSTRAINT [DF__tMenuOfPe__Order__4337C010] DEFAULT (0) FOR [OrderNums]
GO

ALTER TABLE [dbo].[tModel] ADD 
	CONSTRAINT [DF_tModel_OrderNums] DEFAULT (0) FOR [OrderNums]
GO

ALTER TABLE [dbo].[tOrder] ADD 
	CONSTRAINT [DF__tOrder__OrderNO__47C69FAC] DEFAULT ('0') FOR [OrderNO],
	CONSTRAINT [DF__tOrder__Sequence__48BAC3E5] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF__tOrder__BuyDate__49AEE81E] DEFAULT (getdate()) FOR [BuyDate],
	CONSTRAINT [DF__tOrder__AllMoney__4AA30C57] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF__tOrder__UpfrontM__4B973090] DEFAULT (0) FOR [UpfrontMoney],
	CONSTRAINT [DF__tOrder__Status__4C8B54C9] DEFAULT (1) FOR [Status],
	CONSTRAINT [DF__tOrder__WriteTim__4E739D3B] DEFAULT (getdate()) FOR [WriteTime],
	CONSTRAINT [DF_tOrder_Processed] DEFAULT (0) FOR [Processed],
	CONSTRAINT [CKC_STATUS_TORDER] CHECK ([Status] = 5 or ([Status] = 4 or ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))))
GO

ALTER TABLE [dbo].[tPayRakeOff] ADD 
	CONSTRAINT [DF__tPayRakeOf__Year__515009E6] DEFAULT (datepart(year,getdate())) FOR [Year],
	CONSTRAINT [DF_tPayRakeOff_BaseMoney] DEFAULT (0) FOR [BaseMoney],
	CONSTRAINT [DF__tPayRakeO__SellM__52442E1F] DEFAULT (0) FOR [SellMoney],
	CONSTRAINT [DF__tPayRakeOf__Rate__53385258] DEFAULT (0) FOR [Rate],
	CONSTRAINT [DF__tPayRakeO__Rakeo__542C7691] DEFAULT (0) FOR [RakeoffMoney],
	CONSTRAINT [DF__tPayRakeO__Payat__55209ACA] DEFAULT (getdate()) FOR [Payate],
	CONSTRAINT [DF__tPayRakeO__PayTy__5614BF03] DEFAULT (0) FOR [PayType],
	CONSTRAINT [CKC_PAYTYPE_TPAYRAKE] CHECK ([PayType] = 1 or [PayType] = 0)
GO

ALTER TABLE [dbo].[tProductMainPlan] ADD 
	CONSTRAINT [DF__tProductM__PlanT__5DABBF2A] DEFAULT (0) FOR [PlanType],
	CONSTRAINT [DF__tProductM__Statu__5F94079C] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_PLANTYPE_TPRODUCT] CHECK ([PlanType] = 2 or ([PlanType] = 1 or [PlanType] = 0)),
	CONSTRAINT [CKC_STATUS_TPRODUCT] CHECK ([Status] = 2 or ([Status] = 1 or [Status] = 0))
GO

ALTER TABLE [dbo].[tProductPlan] ADD 
	CONSTRAINT [DF__tProductP__Statu__16E43C86] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TPRODUCT1] CHECK ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0)))
GO

ALTER TABLE [dbo].[tProductPlanDetail] ADD 
	CONSTRAINT [DF__tProductP__Statu__1E855E4E] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TPRODUCT2] CHECK ([Status] = 1 or [Status] = 0)
GO

ALTER TABLE [dbo].[tProductPrice] ADD 
	CONSTRAINT [DF__tProductP__SubNu__59E54FE7] DEFAULT (0) FOR [SubNums],
	CONSTRAINT [DF__tProductP__SubPr__5AD97420] DEFAULT (0) FOR [SubPrice]
GO

ALTER TABLE [dbo].[tProductQCRecord] ADD 
	CONSTRAINT [DF__tProductQ__Alrea__6ED64B2C] DEFAULT (0) FOR [AlreadyCheck],
	CONSTRAINT [CKC_ALREADYCHECK_TPRODUCT] CHECK ([AlreadyCheck] = 1 or [AlreadyCheck] = 0)
GO

ALTER TABLE [dbo].[tProductStatusPrice] ADD 
	CONSTRAINT [DF__tProductS__Price__2838E5BA] DEFAULT (0) FOR [Price]
GO

ALTER TABLE [dbo].[tProductStoreNums] ADD 
	CONSTRAINT [DF__tProductS__CurSt__77809FC6] DEFAULT (0) FOR [CurStoreNums],
	CONSTRAINT [DF_tProductStoreNums_AllMoney] DEFAULT (0) FOR [AllMoney]
GO

ALTER TABLE [dbo].[tRakeOff] ADD 
	CONSTRAINT [DF__tRakeOff__Year__5DB5E0CB] DEFAULT (datepart(year,getdate())) FOR [Year],
	CONSTRAINT [DF__tRakeOff__LowVal__5EAA0504] DEFAULT (0) FOR [LowValue],
	CONSTRAINT [DF__tRakeOff__UpperV__5F9E293D] DEFAULT (0) FOR [UpperValue],
	CONSTRAINT [DF__tRakeOff__Rate__60924D76] DEFAULT (0) FOR [Rate]
GO

ALTER TABLE [dbo].[tRakeOffProduct] ADD 
	CONSTRAINT [DF__tRakeOffPr__Rate__385A3EEA] DEFAULT (0) FOR [Rate]
GO

ALTER TABLE [dbo].[tSMSCustomer] ADD 
	CONSTRAINT [DF__tSMSCusto__Succe__664B26CC] DEFAULT (0) FOR [SuccessFlag],
	CONSTRAINT [CKC_SUCCESSFLAG_TSMSCUST] CHECK ([SuccessFlag] = 1 or [SuccessFlag] = 0)
GO

ALTER TABLE [dbo].[tSellBack] ADD 
	CONSTRAINT [DF_tblSellBack_SellBackNO] DEFAULT ('0') FOR [SellBackNO],
	CONSTRAINT [DF_tblSellBack_SequenceNum] DEFAULT (0) FOR [SequenceNum],
	CONSTRAINT [DF_tblSellBack_SellBackDate] DEFAULT (getdate()) FOR [SellBackDate],
	CONSTRAINT [DF_tblSellBack_AllMoney] DEFAULT (0) FOR [AllMoney],
	CONSTRAINT [DF_tblSellBack_UpfrontMoney] DEFAULT (0) FOR [UpfrontMoney],
	CONSTRAINT [DF_tblSellBack_Status] DEFAULT (1) FOR [Status],
	CONSTRAINT [DF_tblSellBack_WriteTime] DEFAULT (getdate()) FOR [WriteTime]
GO

ALTER TABLE [dbo].[tSellPay] ADD 
	CONSTRAINT [DF__tSellPay__PayMon__6A1BB7B0] DEFAULT (0) FOR [PayMoney],
	CONSTRAINT [DF__tSellPay__PayTim__6B0FDBE9] DEFAULT (getdate()) FOR [PayTime],
	CONSTRAINT [DF_tSellPay_PayTypeID] DEFAULT (0) FOR [PayTypeID],
	CONSTRAINT [DF__tSellPay__Type__6C040022] DEFAULT (0) FOR [Type],
	CONSTRAINT [DF__tSellPay__WriteT__6DEC4894] DEFAULT (getdate()) FOR [WriteTime],
	CONSTRAINT [DF_tSellPay_Status] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_TYPE_TSELLPAY] CHECK ([Type] = 1 or [Type] = 0 or [Type] = 2 or [Type] = 3 or [Type] = 4 or [Type] = 5)
GO

ALTER TABLE [dbo].[tSellReport] ADD 
	CONSTRAINT [DF__tSellRepo__Begin__0CD0C267] DEFAULT (getdate()) FOR [BeginDate],
	CONSTRAINT [DF__tSellRepo__EndDa__0DC4E6A0] DEFAULT (getdate()) FOR [EndDate],
	CONSTRAINT [DF__tSellRepo__MakeB__0EB90AD9] DEFAULT (getdate()) FOR [MakeBillDate]
GO

ALTER TABLE [dbo].[tSellReportFirst] ADD 
	CONSTRAINT [DF_tSellReportFirst_CustomerID] DEFAULT (0) FOR [CustomerID],
	CONSTRAINT [DF__tSellRepo__First__1B1EE1BE] DEFAULT (0) FOR [FirstMoney],
	CONSTRAINT [DF__tSellRepo__Repor__1C1305F7] DEFAULT (getdate()) FOR [ReportDate],
	CONSTRAINT [DF__tSellRepo__Repor__1D072A30] DEFAULT (0) FOR [ReportID]
GO

ALTER TABLE [dbo].[tSendWorker] ADD 
	CONSTRAINT [DF__tSendWork__Statu__76776CF4] DEFAULT (0) FOR [Status],
	CONSTRAINT [CKC_STATUS_TSENDWOR] CHECK ([Status] = 6 or ([Status] = 5 or ([Status] = 4 or ([Status] = 3 or ([Status] = 2 or ([Status] = 1 or [Status] = 0))))))
GO

ALTER TABLE [dbo].[tSms] ADD 
	CONSTRAINT [DF__tSms__SubmitTime__70C8B53F] DEFAULT (getdate()) FOR [SubmitTime],
	CONSTRAINT [DF__tSms__Status__71BCD978] DEFAULT (1) FOR [Status],
	CONSTRAINT [CKC_STATUS_TSMS] CHECK ([Status] = 2 or ([Status] = 1 or [Status] = 0))
GO

ALTER TABLE [dbo].[tStoreHouse] ADD 
	CONSTRAINT [DF__tStoreHou__AreaN__758D6A5C] DEFAULT (0) FOR [AreaNums]
GO

ALTER TABLE [dbo].[tSubProcStatusPrice] ADD 
	CONSTRAINT [DF__tSubProcS__Price__2C09769E] DEFAULT (0) FOR [Price]
GO

ALTER TABLE [dbo].[tTakeoutForm] ADD 
	CONSTRAINT [DF__tTakeoutF__UseNu__7775B2CE] DEFAULT (0) FOR [UseNums]
GO

ALTER TABLE [dbo].[tUnit] ADD 
	CONSTRAINT [DF__tUnit__GoodsType__7A521F79] DEFAULT (2) FOR [GoodsType],
	CONSTRAINT [CKC_GOODSTYPE_TUNIT] CHECK ([GoodsType] = 4 or ([GoodsType] = 3 or ([GoodsType] = 2 or ([GoodsType] = 1 or [GoodsType] = 0))))
GO

ALTER TABLE [dbo].[tWorkpreface] ADD 
	CONSTRAINT [DF__tWorkpref__Statu__7C30464A] DEFAULT ('0') FOR [Status],
	CONSTRAINT [CKC_STATUS_TWORKPRE] CHECK ([Status] is null or ([Status] = '2' or ([Status] = '1' or [Status] = '0')))
GO

ALTER TABLE [dbo].[tYearTaskMoney] ADD 
	CONSTRAINT [DF__tYearTaskM__Year__000AF8CF] DEFAULT (datepart(year,getdate())) FOR [Year],
	CONSTRAINT [DF__tYearTask__Total__00FF1D08] DEFAULT (0) FOR [TotalMoney],
	CONSTRAINT [DF__tYearTask__BaseR__01F34141] DEFAULT (0) FOR [BaseRate],
	CONSTRAINT [DF__tYearTask__Start__02E7657A] DEFAULT (getdate()) FOR [StartDate],
	CONSTRAINT [DF__tYearTask__EndDa__03DB89B3] DEFAULT (getdate()) FOR [EndDate]
GO

ALTER TABLE [dbo].[tAfterService] ADD 
	CONSTRAINT [FK_TAFTERSE_TO_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

ALTER TABLE [dbo].[tArea] ADD 
	CONSTRAINT [FK_TAREA_TO_TAREA] FOREIGN KEY 
	(
		[ParentAreaID]
	) REFERENCES [dbo].[tArea] (
		[AreaID]
	)
GO

ALTER TABLE [dbo].[tBaseDataTree] ADD 
	CONSTRAINT [FK_TBASEDAT_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[ParentDataID]
	) REFERENCES [dbo].[tBaseDataTree] (
		[DataID]
	)
GO

ALTER TABLE [dbo].[tBillOfExchange] ADD 
	CONSTRAINT [FK_TBILLOFE_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[FromStorerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFE_REFERENCE_TEMPLOYE_Exch] FOREIGN KEY 
	(
		[ToStorerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFE_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[FromStoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	),
	CONSTRAINT [FK_TBILLOFE_REFERENCE_TSTOREHO_TO] FOREIGN KEY 
	(
		[ToStoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	),
	CONSTRAINT [FK_TEMPLOYE_ExchEmpID] FOREIGN KEY 
	(
		[ExchangeEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	)
GO

ALTER TABLE [dbo].[tBillOfPutin] ADD 
	CONSTRAINT [FK_TBILLOFP_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[PutinEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFP_REFERENCE_TEMPLOYE10] FOREIGN KEY 
	(
		[StorerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFP_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tBillOfSell] ADD 
	CONSTRAINT [FK_TBILLOFS_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[GatheringTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TBILLOFS_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TBILLOFS_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[DeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	),
	CONSTRAINT [FK_TBILLOFS_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[SellerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFS_REFERENCE_TORDER] FOREIGN KEY 
	(
		[OrderID]
	) REFERENCES [dbo].[tOrder] (
		[OrderID]
	),
	CONSTRAINT [FK_TBILLOFS_TO_TAREA] FOREIGN KEY 
	(
		[AreaID]
	) REFERENCES [dbo].[tArea] (
		[AreaID]
	)
GO

ALTER TABLE [dbo].[tBillOfTakeout] ADD 
	CONSTRAINT [FK_TBILLOFT_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[TakeOutEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFT_REFERENCE_TEMPLOYE01] FOREIGN KEY 
	(
		[StorerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TBILLOFT_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tBuyApplyDetail] ADD 
	CONSTRAINT [FK_TBUYAPPL_APPLYID_TBUYAPPL] FOREIGN KEY 
	(
		[SheetID]
	) REFERENCES [dbo].[tBuyApply] (
		[SheetID]
	)
GO

ALTER TABLE [dbo].[tBuyPay] ADD 
	CONSTRAINT [FK_TBUYPAY_REFERENCE_TBILLOFB] FOREIGN KEY 
	(
		[BillOfBuyID]
	) REFERENCES [dbo].[tBillOfBuy] (
		[BillOfBuyID]
	)
GO

ALTER TABLE [dbo].[tCalcDetail] ADD 
	CONSTRAINT [FK_TCALCDET_REFERENCE_TCALCSHE] FOREIGN KEY 
	(
		[DetailID]
	) REFERENCES [dbo].[tCalcSheetDetail] (
		[DetailID]
	)
GO

ALTER TABLE [dbo].[tCalcSheet] ADD 
	CONSTRAINT [FK_TCALCSHE_REFERENCE_TCLASSDO] FOREIGN KEY 
	(
		[ClassID]
	) REFERENCES [dbo].[tClassDoc] (
		[ClassID]
	)
GO

ALTER TABLE [dbo].[tCalcSheetDetail] ADD 
	CONSTRAINT [FK_TCALCSHE_REFERENCE_TCALCSHE] FOREIGN KEY 
	(
		[SheetID]
	) REFERENCES [dbo].[tCalcSheet] (
		[SheetID]
	)
GO

ALTER TABLE [dbo].[tCheckTable] ADD 
	CONSTRAINT [FK_TCHECKTA_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[CheckEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TCHECKTA_REFERENCE_TEMPLOYE1] FOREIGN KEY 
	(
		[CheckEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TCHECKTA_REFERENCE_TEMPLOYE2] FOREIGN KEY 
	(
		[StorerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TCHECKTA_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tCompany] ADD 
	CONSTRAINT [FK_TCOMPANY_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[CompTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TCOMPANY_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[ParentCompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	)
GO

ALTER TABLE [dbo].[tContract] ADD 
	CONSTRAINT [FK_TCONTRAC_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

ALTER TABLE [dbo].[tCrafRouteDetail] ADD 
	CONSTRAINT [FK_TCRAFROU_REFERENCE_TCRAFROU] FOREIGN KEY 
	(
		[CrafID]
	) REFERENCES [dbo].[tCrafRoute] (
		[CrafID]
	)
GO

ALTER TABLE [dbo].[tCustomer] ADD 
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[CustomerTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[DeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	),
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[EmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TEMPLOYE02] FOREIGN KEY 
	(
		[EmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TCUSTOME_TO_TAREA] FOREIGN KEY 
	(
		[AreaID]
	) REFERENCES [dbo].[tArea] (
		[AreaID]
	)
GO

ALTER TABLE [dbo].[tCustomerPay] ADD 
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TCUSTOME1] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

ALTER TABLE [dbo].[tCustomerProductPrice] ADD 
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TCUSTOME_REFERENCE_TGOODS] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tDepartment] ADD 
	CONSTRAINT [FK_TDEPARTM_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	),
	CONSTRAINT [FK_TDEPARTM_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[ParentDeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	)
GO

ALTER TABLE [dbo].[tDetailOfBuy] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TBILLOFB] FOREIGN KEY 
	(
		[BillOfBuyID]
	) REFERENCES [dbo].[tBillOfBuy] (
		[BillOfBuyID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tDetailOfCheckTable] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TCHECKTA1] FOREIGN KEY 
	(
		[CheckTableID]
	) REFERENCES [dbo].[tCheckTable] (
		[CheckTableID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS1] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TSTOREHO1] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tDetailOfExchange] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TBILLOFE] FOREIGN KEY 
	(
		[BillOfExchangeID]
	) REFERENCES [dbo].[tBillOfExchange] (
		[BillOfExchangeID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS_Exchage] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tDetailOfOrder] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS04] FOREIGN KEY 
	(
		[ProcID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TORDER] FOREIGN KEY 
	(
		[OrderID]
	) REFERENCES [dbo].[tOrder] (
		[OrderID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TUNIT] FOREIGN KEY 
	(
		[UnitID]
	) REFERENCES [dbo].[tUnit] (
		[UnitID]
	)
GO

ALTER TABLE [dbo].[tDetailOfSell] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TBILLOFS] FOREIGN KEY 
	(
		[BillOfSellID]
	) REFERENCES [dbo].[tBillOfSell] (
		[BillOfSellID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS06] FOREIGN KEY 
	(
		[ProcID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tDetailOfSellBack] ADD 
	CONSTRAINT [FK_tDetailOfSellBack_tSellBack] FOREIGN KEY 
	(
		[SellBackID]
	) REFERENCES [dbo].[tSellBack] (
		[SellBackID]
	)
GO

ALTER TABLE [dbo].[tDetailOfSellReport] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TSELLREP] FOREIGN KEY 
	(
		[ReportID]
	) REFERENCES [dbo].[tSellReport] (
		[ReportID]
	),
	CONSTRAINT [FK_tDetailOfSellReport_tArea] FOREIGN KEY 
	(
		[AreaID]
	) REFERENCES [dbo].[tArea] (
		[AreaID]
	),
	CONSTRAINT [FK_tDetailOfSellReport_tEmployee] FOREIGN KEY 
	(
		[EmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	)
GO

ALTER TABLE [dbo].[tDetailOfTakeout] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TBILLOFT] FOREIGN KEY 
	(
		[BillOfTakeoutID]
	) REFERENCES [dbo].[tBillOfTakeout] (
		[BillOfTakeoutID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TGOODS08] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TSTOREHO07] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tDetailOfTakeoutSource] ADD 
	CONSTRAINT [FK_TDETAILO_REFERENCE_TDETAIL123] FOREIGN KEY 
	(
		[DetailIDOfPutin]
	) REFERENCES [dbo].[tDetailOfPutin] (
		[DetailID]
	),
	CONSTRAINT [FK_TDETAILO_REFERENCE_TDETAILO] FOREIGN KEY 
	(
		[DetailID]
	) REFERENCES [dbo].[tDetailOfTakeout] (
		[DetailID]
	)
GO

ALTER TABLE [dbo].[tDocMain] ADD 
	CONSTRAINT [FK_TDOCMAIN_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	),
	CONSTRAINT [FK_TDOCMAIN_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[DeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	)
GO

ALTER TABLE [dbo].[tDocRS] ADD 
	CONSTRAINT [FK_TDOCRS_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	),
	CONSTRAINT [FK_TDOCRS_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[DeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	),
	CONSTRAINT [FK_TDOCRS_REFERENCE_TDOCMAIN] FOREIGN KEY 
	(
		[DocID]
	) REFERENCES [dbo].[tDocMain] (
		[DocID]
	)
GO

ALTER TABLE [dbo].[tDocType] ADD 
	CONSTRAINT [FK_TDOCTYPE_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	)
GO

ALTER TABLE [dbo].[tEmployee] ADD 
	CONSTRAINT [FK_TEMPLOYE_REFERENCE_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	),
	CONSTRAINT [FK_TEMPLOYE_REFERENCE_TDEPARTM] FOREIGN KEY 
	(
		[DeptID]
	) REFERENCES [dbo].[tDepartment] (
		[DeptID]
	)
GO

ALTER TABLE [dbo].[tGetMaterialDetail] ADD 
	CONSTRAINT [FK_TGETMATE_REFERENCE_TGETMATE] FOREIGN KEY 
	(
		[BillOfTakeoutID]
	) REFERENCES [dbo].[tGetMaterial] (
		[BillOfTakeoutID]
	)
GO

ALTER TABLE [dbo].[tGoods] ADD 
	CONSTRAINT [FK_TGOODS_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[ModelID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TGOODS_REFERENCE_TBASEDAT09] FOREIGN KEY 
	(
		[SpecID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TGOODS_REFERENCE_TBASEDAT10] FOREIGN KEY 
	(
		[GoodsTypeID]
	) REFERENCES [dbo].[tBaseDataTree] (
		[DataID]
	),
	CONSTRAINT [FK_TGOODS_REFERENCE_TUNIT] FOREIGN KEY 
	(
		[UnitID]
	) REFERENCES [dbo].[tUnit] (
		[UnitID]
	)
GO

ALTER TABLE [dbo].[tGroupEmployee] ADD 
	CONSTRAINT [FK_TGROUPEM_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[DataID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TGROUPEM_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[EmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	)
GO

ALTER TABLE [dbo].[tKeepFee] ADD 
	CONSTRAINT [FK_TKEEPFEE_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[FeeTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TKEEPFEE_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TKEEPFEE_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[UseEmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_tKeepFee_tBaseData] FOREIGN KEY 
	(
		[PayType]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	)
GO

ALTER TABLE [dbo].[tMenu] ADD 
	CONSTRAINT [FK_tMenu_REFERENCE_tMenu] FOREIGN KEY 
	(
		[PMenuID]
	) REFERENCES [dbo].[tMenu] (
		[MenuID]
	)
GO

ALTER TABLE [dbo].[tMenuOfPerson] ADD 
	CONSTRAINT [FK_TMENUOFP_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[EmpID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TMENUOFP_REFERENCE_TMENU] FOREIGN KEY 
	(
		[MenuID]
	) REFERENCES [dbo].[tMenu] (
		[MenuID]
	)
GO

ALTER TABLE [dbo].[tOrder] ADD 
	CONSTRAINT [FK_TORDER_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[TransTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TORDER_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TORDER_REFERENCE_TEMPLOYE] FOREIGN KEY 
	(
		[SellerID]
	) REFERENCES [dbo].[tEmployee] (
		[EmpID]
	),
	CONSTRAINT [FK_TORDER_TO_TAREA] FOREIGN KEY 
	(
		[AreaID]
	) REFERENCES [dbo].[tArea] (
		[AreaID]
	)
GO

ALTER TABLE [dbo].[tPayRakeOff] ADD 
	CONSTRAINT [FK_TPAYRAKE_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

ALTER TABLE [dbo].[tProductInstallDetail] ADD 
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TPRODUCT] FOREIGN KEY 
	(
		[InsID]
	) REFERENCES [dbo].[tProductInstall] (
		[InsID]
	)
GO

ALTER TABLE [dbo].[tProductMainPlanDetail] ADD 
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TPRODUCT1] FOREIGN KEY 
	(
		[SheetID]
	) REFERENCES [dbo].[tProductMainPlan] (
		[SheetID]
	)
GO

ALTER TABLE [dbo].[tProductPlanDetail] ADD 
	CONSTRAINT [FK_TPRODUCT_申请计划单ID_TPRODUCT] FOREIGN KEY 
	(
		[SheetID]
	) REFERENCES [dbo].[tProductPlan] (
		[SheetID]
	)
GO

ALTER TABLE [dbo].[tProductQCRecDetail] ADD 
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TPRODUCT2] FOREIGN KEY 
	(
		[RecordID]
	) REFERENCES [dbo].[tProductQCRecord] (
		[RecordID]
	),
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TQUANTIT] FOREIGN KEY 
	(
		[ProjectID]
	) REFERENCES [dbo].[tQuantityCheckstandard] (
		[ProjectID]
	)
GO

ALTER TABLE [dbo].[tProductStatusPrice] ADD 
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[ProcStatusID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TGOODS] FOREIGN KEY 
	(
		[ProcID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tProductStoreNums] ADD 
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TGOODS1] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	),
	CONSTRAINT [FK_TPRODUCT_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[StoreHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tQuantityCheckstandard] ADD 
	CONSTRAINT [FK_TQUANTIT_REFERENCE_TQUANTIT] FOREIGN KEY 
	(
		[ParentID]
	) REFERENCES [dbo].[tQuantityCheckstandard] (
		[ProjectID]
	)
GO

ALTER TABLE [dbo].[tRakeOff] ADD 
	CONSTRAINT [FK_TRAKEOFF_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

ALTER TABLE [dbo].[tRakeOffGoods] ADD 
	CONSTRAINT [FK_TRAKEOFF_REFERENCE_TPAYRAKE] FOREIGN KEY 
	(
		[RakeOffID]
	) REFERENCES [dbo].[tPayRakeOff] (
		[RakeOffID]
	)
GO

ALTER TABLE [dbo].[tRakeOffProduct] ADD 
	CONSTRAINT [FK_TRAKEOFFPro_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TRAKEOFFPro_REFERENCE_TGOODS] FOREIGN KEY 
	(
		[GoodsID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tReInfo] ADD 
	CONSTRAINT [FK_TREINFO_REFERENCE_TDOCMAIN] FOREIGN KEY 
	(
		[DocID]
	) REFERENCES [dbo].[tDocMain] (
		[DocID]
	)
GO

ALTER TABLE [dbo].[tSMSCustomer] ADD 
	CONSTRAINT [FK_TSMSCUST_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_TSMSCUST_REFERENCE_TSMS] FOREIGN KEY 
	(
		[SmsID]
	) REFERENCES [dbo].[tSms] (
		[SmsID]
	)
GO

ALTER TABLE [dbo].[tSellPay] ADD 
	CONSTRAINT [FK_TSELLPAY_REFERENCE_TBASEDAT] FOREIGN KEY 
	(
		[PayTypeID]
	) REFERENCES [dbo].[tBaseData] (
		[DataID]
	),
	CONSTRAINT [FK_TSELLPAY_REFERENCE_TBILLOFS] FOREIGN KEY 
	(
		[BillOfSellID]
	) REFERENCES [dbo].[tBillOfSell] (
		[BillOfSellID]
	),
	CONSTRAINT [FK_tSellPay_tCustomer] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	),
	CONSTRAINT [FK_tSellPay_tCustomerPay] FOREIGN KEY 
	(
		[CPayID]
	) REFERENCES [dbo].[tCustomerPay] (
		[PayID]
	)
GO

ALTER TABLE [dbo].[tSendWorkerDetail] ADD 
	CONSTRAINT [FK_TSENDWOR_REFERENCE_TSENDWOR] FOREIGN KEY 
	(
		[SheetID]
	) REFERENCES [dbo].[tSendWorker] (
		[SheetID]
	)
GO

ALTER TABLE [dbo].[tSheetCode] ADD 
	CONSTRAINT [FK_SHEETCOD_TO_TCOMPANY] FOREIGN KEY 
	(
		[CompID]
	) REFERENCES [dbo].[tCompany] (
		[CompID]
	)
GO

ALTER TABLE [dbo].[tStoreHouse] ADD 
	CONSTRAINT [FK_TSTOREHO_REFERENCE_TSTOREHO] FOREIGN KEY 
	(
		[ParentHouseID]
	) REFERENCES [dbo].[tStoreHouse] (
		[StoreHouseID]
	)
GO

ALTER TABLE [dbo].[tSubProcStatusPrice] ADD 
	CONSTRAINT [FK_TSUBPROC_REFERENCE_TGOODS] FOREIGN KEY 
	(
		[ProcID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tTakeoutForm] ADD 
	CONSTRAINT [FK_TTAKEOUT_REFERENCE_TDETAILO] FOREIGN KEY 
	(
		[TakeoutDetailID]
	) REFERENCES [dbo].[tDetailOfTakeout] (
		[DetailID]
	),
	CONSTRAINT [FK_TTAKEOUT_REFERENCE_TDETAILO12] FOREIGN KEY 
	(
		[PutinDetailID]
	) REFERENCES [dbo].[tDetailOfPutin] (
		[DetailID]
	)
GO

ALTER TABLE [dbo].[tUnitConversion] ADD 
	CONSTRAINT [FK_TUNITCON_REFERENCE_TUNIT] FOREIGN KEY 
	(
		[UnitID]
	) REFERENCES [dbo].[tUnit] (
		[UnitID]
	),
	CONSTRAINT [FK_TUNITCON_REFERENCE_TUNIT13] FOREIGN KEY 
	(
		[ConvUnitID]
	) REFERENCES [dbo].[tUnit] (
		[UnitID]
	),
	CONSTRAINT [FK_tUnitConversion_tGoods] FOREIGN KEY 
	(
		[GoodID]
	) REFERENCES [dbo].[tGoods] (
		[GoodsID]
	)
GO

ALTER TABLE [dbo].[tWorkpreface] ADD 
	CONSTRAINT [FK_TWORKPRE_REFERENCE_TEQUIPME] FOREIGN KEY 
	(
		[EqID]
	) REFERENCES [dbo].[tEquipmentsDoc] (
		[EqID]
	)
GO

ALTER TABLE [dbo].[tYearTaskMoney] ADD 
	CONSTRAINT [FK_TYEARTAS_REFERENCE_TCUSTOME] FOREIGN KEY 
	(
		[CustomerID]
	) REFERENCES [dbo].[tCustomer] (
		[CustomerID]
	)
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwArea
AS
SELECT dbo.tArea.ParentAreaID AS name1, tArea_1.ParentAreaID AS name2, 
      tArea_2.ParentAreaID AS name3
FROM dbo.tArea INNER JOIN
      dbo.tArea tArea_1 ON dbo.tArea.ParentAreaID = tArea_1.AreaID INNER JOIN
      dbo.tArea tArea_2 ON dbo.tArea.ParentAreaID = tArea_2.AreaID AND 
      tArea_1.ParentAreaID = tArea_2.AreaID

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwSellBack	--根据销售退货建立的视图
AS
SELECT dbo.tSellBack.CustomerID,dbo.tGoods.GoodsTypeID,dbo.tDetailOfSellBack.ProcID, 
      dbo.tDetailOfSellBack.GoodsCode, dbo.tDetailOfSellBack.GoodsName, 
      dbo.tDetailOfSellBack.CancelNums, dbo.tDetailOfSellBack.CancelDate, 
     dbo.tDetailOfSellBack.CancelMoney,
      dbo.tDetailOfSellBack.Price
FROM dbo.tDetailOfSellBack INNER JOIN
      dbo.tSellBack ON dbo.tDetailOfSellBack.SellBackID = dbo.tSellBack.SellBackID

	INNER JOIN dbo.tGoods ON dbo.tDetailOfSellBack.ProcID=dbo.tGoods.GoodsID

where tSellBack.status=1


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwEmpSea
AS
SELECT dbo.tCompany.CompName AS ComName, 
      dbo.tDepartment.DeptName AS DepName, dbo.tEmployee.EmpID, 
      dbo.tEmployee.EmpName, dbo.tEmployee.Type, dbo.tEmployee.EmpNO, 
      dbo.tEmployee.CompID, dbo.tEmployee.DeptID
FROM dbo.tEmployee INNER JOIN
      dbo.tCompany ON dbo.tEmployee.CompID = dbo.tCompany.CompID INNER JOIN
      dbo.tDepartment ON dbo.tEmployee.DeptID = dbo.tDepartment.DeptID

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwCustomerList
AS
SELECT cut.*, emp.EmpName, dep.DeptName, bdt.DataValue AS CustomerType, 
      bdt2.DataValue AS TransType,
          (SELECT storage.fnGetParentAreaStr(cut.AreaID)) AS AreaName
FROM dbo.tCustomer cut INNER JOIN
      dbo.tEmployee emp ON cut.EmpID = emp.EmpID INNER JOIN
      dbo.tDepartment dep ON cut.DeptID = dep.DeptID INNER JOIN
      dbo.tBaseData bdt ON cut.CustomerTypeID = bdt.DataID INNER JOIN
      dbo.tBaseData bdt2 ON cut.TransTypeID = bdt2.DataID

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
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
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwContList
AS
SELECT dbo.tCustomer.FullName AS CustName,dbo.tCustomer.DelFlag, dbo.tContract.*
FROM dbo.tContract INNER JOIN
      dbo.tCustomer ON dbo.tContract.CustomerID = dbo.tCustomer.CustomerID


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwKeepFee
AS
SELECT dbo.tKeepFee.*, dbo.tBaseData.DataValue AS TypeName, 
      dbo.tCustomer.FullName AS CustName, dbo.tCustomer.DelFlag,B2.DataValue AS PayTypeName
FROM dbo.tKeepFee INNER JOIN
      dbo.tBaseData ON dbo.tKeepFee.FeeTypeID = dbo.tBaseData.DataID INNER JOIN
      dbo.tCustomer ON 
      dbo.tKeepFee.CustomerID = dbo.tCustomer.CustomerID INNER JOIN
      dbo.tBaseData B2 ON dbo.tKeepFee.PayType = B2.DataID


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwSMSList
AS
SELECT dbo.tSms.Content AS SMSContent, dbo.tCustomer.FullName AS CustName, dbo.tCustomer.DelFlag,
      dbo.tSMSCustomer.*, dbo.tSms.SubmitTime AS SendTime
FROM dbo.tSMSCustomer LEFT OUTER JOIN
      dbo.tCustomer ON 
      dbo.tSMSCustomer.CustomerID = dbo.tCustomer.CustomerID INNER JOIN
      dbo.tSms ON dbo.tSMSCustomer.SmsID = dbo.tSms.SmsID

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwService
AS
SELECT dbo.tAfterService.*, dbo.tCustomer.FullName AS CustName,dbo.tCustomer.DelFlag
FROM dbo.tAfterService INNER JOIN
      dbo.tCustomer ON dbo.tAfterService.CustomerID = dbo.tCustomer.CustomerID



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.vwSell --根据销售单建立的视图，已将退货数量 与退货金额从销售数量、销售额中扣减
AS 

SELECT dbo.tBillOfSell.CustomerID,dbo.tgoods.goodsTypeID,dbo.tDetailOfSell.ProcID, dbo.tDetailOfSell.GoodsCode, 
      dbo.tDetailOfSell.GoodsName, dbo.tDetailOfSell.BuyPrice, 
      dbo.tDetailOfSell.BuyPrice * (dbo.tDetailOfSell.Nums - dbo.tDetailOfSell.CancelNums) 
      AS BuyMoney, dbo.tDetailOfSell.Price AS SellPrice, 
      (dbo.tDetailOfSell.FactMoney-dbo.tDetailOfSell.CancelMoney) AS SellMoney, 
      (dbo.tDetailOfSell.Nums - dbo.tDetailOfSell.CancelNums) AS SellNums, 
      dbo.tDetailOfSell.SellDate,
      dbo.tDetailOfSell.FactMoney,
     dbo.tDetailOfSell.CancelMoney
FROM dbo.tDetailOfSell 

	INNER JOIN
      dbo.tBillOfSell ON dbo.tDetailOfSell.BillOfSellID = dbo.tBillOfSell.BillOfSellID

	INNER JOIN
      tGoods ON tDetailOfSell.ProcID = tGoods.GoodsID

    where tBillOfSell.status=1



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

--显示所有销售收款已审核的明细，以及对应的客户与业务员
CREATE VIEW dbo.vwSellPay
AS
SELECT dbo.tSellPay.PayID, dbo.tSellPay.PayMan, dbo.tSellPay.PayMoney, 
      dbo.tSellPay.PayTime, dbo.tSellPay.RecvedMan, dbo.tSellPay.Type, 
      dbo.tSellPay.WriteMan, dbo.tSellPay.WriteTime, dbo.tSellPay.CheckMan, 
      dbo.tSellPay.CheckTime, dbo.tSellPay.CustomerID, dbo.tSellPay.CPayID, 
      dbo.tCustomer.CustNO, dbo.tCustomer.ShortName, dbo.tCustomer.FullName, dbo.tCustomer.empID,
      dbo.tEmployee.EmpNO, dbo.tEmployee.EmpName
FROM dbo.tSellPay INNER JOIN
      dbo.tCustomer ON dbo.tSellPay.CustomerID = dbo.tCustomer.CustomerID INNER JOIN
      dbo.tEmployee ON dbo.tCustomer.EmpID = dbo.tEmployee.EmpID
WHERE (dbo.tSellPay.Status = 1) AND (dbo.tEmployee.Type = 1)




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：
	备份数据库。
参数：
	@DiskUrl	varchar(250)		备份的路径
	@DBName	varchar(250)
返回：
	0	成功
	-1	失败
*/
CREATE PROCEDURE [Storage].[sp_BackDatabase](
	@DiskUrl  varchar(250),
	@DBName	varchar(250)
) AS
BEGIN
	set nocount on
	declare @SqlStr varchar(250)
	
	set @SqlStr = 'BACKUP DATABASE '+@DBName+' to disk='''+@DiskUrl+''' with noinit'
	exec(@SqlStr)
	if @@ERROR != 0 goto Err_Proc
	else goto OK
	
Err_Proc:
	set nocount off
	return -1
OK:
	set nocount off
	return 0

END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据年份、月份时间区间，以及产品的分类查询出产品的采购情况
	包括采购的数量，采购额，与同期比较的差额、差率
输入参数：
		@PcurYear=当前年 eg:2006
		@PlastYear=上一年 eg:2005
		@PstartMonth=启始月份
		@PendMonth=终止月份
		@PproClassID=指定的产品分类ID
		@PproID=指定的产品ID
		@GoodsType=产品类型
	
*/

CREATE PROCEDURE [Storage].[sp_CalBuyProduct]

@PcurYear varchar(50),
@PlastYear varchar(50),
@PstartMonth varchar(50),
@PendMonth varchar(50),
@GoodsType int=0,
@PproClassID int = 0,
@PproID int = 0

 AS

set nocount on

--declare @GoodsType varchar(50 )
declare @pSql varchar(4000)
declare @pSqlCondition varchar(200)

--set @GoodsType = '0'	--产品类型 0-产品 1-半成品 2-产品(成品)

set @pSql='select G.GoodsID,G.GoodsCode,G.goodsname,'
set @pSql=@pSql+@PcurYear+' as curYear,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0))+'' / ''+convert(varchar(50),isnull(C2.resultNums,0)))SellNums,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0)-isnull(C2.resultNums,0)))SellNumsMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2), isnull(C1.resultNums,0)/isnull(C2.resultNums,1)*100)))SellNumsRate,'
set @pSql=@pSql+@PlastYear+' as lastYear,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0))+'' / ''+convert(varchar(50),isnull(C2.resultMoney,0)))SellMoney,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0)-isnull(C2.resultMoney,0)))SellMoneyMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2),isnull(C1.resultMoney,0)/isnull(C2.resultMoney,1)*100)))SellMoneyRate'
set @pSql=@pSql+' from ( '

set @pSql=@pSql+' SELECT  *  FROM TGoods  WHERE  GoodsType='+convert(varchar(50),@GoodsType)+'  '

if(@PproClassID!=0)
    set @pSql=@pSql+' AND GoodsTypeID in ('+storage.fnGetBaseDataClassStr(convert(varchar(50),@PproClassID),0,2)+')  '

if(@PproID!=0)
   set @pSql=@pSql+' AND GoodsID='+convert(varchar(50),@PproID)+'  '


set @pSql=@pSql+' ) G '


set @pSql=@pSql+'  left join '
set @pSql=@pSql+' (select goodsID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy a join tBillOfBuy b on a.BillOfBuyID=b.BillOfBuyID '
set @pSql=@pSql+' where b.status=1 and  (year(a.BuyDate)='+@PcurYear+' and (month(a.BuyDate)>='+@PstartMonth+' and month(a.BuyDate)<='+@PendMonth+')) group by goodsID) C1 '
set @pSql=@pSql+' on G.GoodsID=C1.goodsID '
set @pSql=@pSql+'  left join '
set @pSql=@pSql+' (select goodsID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy a join tBillOfBuy b on a.BillOfBuyID=b.BillOfBuyID '
set @pSql=@pSql+' where b.status=1 and (year(a.BuyDate)='+@PlastYear+' and (month(a.BuyDate)>='+@PstartMonth+' and month(a.BuyDate)<='+@PendMonth+')) group by goodsID) C2 '
set @pSql=@pSql+' on G.GoodsID=C2.goodsID '


--print @pSql

set nocount off
exec(@pSql)
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据年份、月份时间区间，以及产品的分类查询出不同采购员对产品的销售情况
	包括采购的数量，采购额，与同期比较的差额、差率
输入参数：
		@PcurYear=当前年 eg:2006
		@PlastYear=上一年 eg:2005
		@PstartMonth=启始月份
		@PendMonth=终止月份
		@PBuyerID=指定的采购员
		@PproID=指定的产品ID
	
*/

CREATE PROCEDURE [Storage].[sp_CalBuyProductOfBuyer]

@PcurYear varchar(50),
@PlastYear varchar(50),
@PstartMonth varchar(50),
@PendMonth varchar(50),
@PBuyerID int=0, --为0时为不指定业务员
@PproID int = 0

 AS

set nocount on

declare @GoodsType varchar(50 )
declare @pSql varchar(4000)
declare @pSqlCondition varchar(200)


set @pSql='select empID,empNo,empName,'
set @pSql=@pSql+' '''+@PcurYear+''' as curYear, '
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0))+'' / ''+convert(varchar(50),isnull(C2.resultNums,0)))SellNums,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0)-isnull(C2.resultNums,0)))SellNumsMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2), isnull(C1.resultNums,0)/isnull(C2.resultNums,1)*100)))SellNumsRate,'
set @pSql=@pSql+' '''+@PlastYear+''' as lastYear,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0))+'' / ''+convert(varchar(50),isnull(C2.resultMoney,0)))SellMoney,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0)-isnull(C2.resultMoney,0)))SellMoneyMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2),isnull(C1.resultMoney,0)/isnull(C2.resultMoney,1)*100)))SellMoneyRate'

set @pSql=@pSql+' from (select * from tEmployee where type=0'

if @PBuyerID!=0
   set @pSql=@pSql+' and empID='+convert(varchar(50),@PBuyerID)+' '  	--指定显示某一业务员的统计信息

set @pSql=@pSql+'  ) G '

set @pSql=@pSql+' left join ( select BuyerID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy detail join tBillOfBuy main on detail.billOfBuyID=main.billOfBuyID '
set @pSql=@pSql+' where main.status=1 and (year(detail.buyDate)='+ @PcurYear+' and (month(detail.buyDate)>='+@PstartMonth+' and month(detail.buyDate)<='+@PendMonth+')) '

if @PproID!=0
   set @pSql=@pSql+' and goodsID='+convert(varchar(50),@PproID)  --指定显示某一商品的统计信息

set @pSql=@pSql+' group by BuyerID ) C1 '
set @pSql=@pSql+' on G.empID=C1.BuyerID '

set @pSql=@pSql+' left join (select BuyerID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy detail join tBillOfBuy main on detail.billOfBuyID=main.billOfBuyID '
set @pSql=@pSql+'  where main.status=1 and (year(detail.buyDate)= '+@PlastYear+' and (month(detail.buyDate)>='+@PstartMonth+' and month(detail.buyDate)<='+@PendMonth+')) '

if @PproID!=0
   set @pSql=@pSql+' and goodsID='+convert(varchar(50),@PproID)  --指定显示某一商品的统计信息

set @pSql=@pSql+' group by BuyerID) C2 '

set @pSql=@pSql+' on G.empID=C2.BuyerID '


--print @pSql

set nocount off
exec(@pSql)
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：根据年份、月份时间区间，查询出不同材料提供商对产品的供应情况
	包括销售的数量，销售额，与同期比较的差额、差率
输入参数：
		@PcurYear=当前年 eg:2006
		@PlastYear=上一年 eg:2005
		@PstartMonth=启始月份
		@PendMonth=终止月份
		@PcustomerID=指定的供应商
		@PproID=指定的材料ID
	
*/

CREATE PROCEDURE [Storage].[sp_CalBuyProductOfProvider]

@PcurYear varchar(50),
@PlastYear varchar(50),
@PstartMonth varchar(50),
@PendMonth varchar(50),
@PcustomerID int=0, --默认为不指定供应商ID，则显示所有供应商的供应情况
@PproID int=0

 AS

set nocount on

declare @GoodsType varchar(50 )
declare @pSql varchar(4000)



set @pSql='select G.CustomerID,CustNO,ShortName,'
set @pSql=@pSql+''''+@PcurYear+''' as curYear,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0))+'' / ''+convert(varchar(50),isnull(C2.resultNums,0)))SellNums,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0)-isnull(C2.resultNums,0)))SellNumsMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2), isnull(C1.resultNums,0)/isnull(C2.resultNums,1)*100)))SellNumsRate,'
set @pSql=@pSql+''''+@PlastYear+''' as lastYear,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0))+'' / ''+convert(varchar(50),isnull(C2.resultMoney,0)))SellMoney,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0)-isnull(C2.resultMoney,0)))SellMoneyMargin,'
set @pSql=@pSql+'(convert(varchar(50), convert(decimal(10,2),isnull(C1.resultMoney,0)/isnull(C2.resultMoney,1)*100)))SellMoneyRate'
set @pSql=@pSql+' from (select * from tCustomer '
	if(@PcustomerID!=0)
	set @pSql=@pSql+' where CustomerID='+convert(varchar(50),@PcustomerID)

set @pSql=@pSql+'  ) G '
set @pSql=@pSql+' left join '
set @pSql=@pSql+'('
set @pSql=@pSql+'select CustomerID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy detail join tBillOfBuy main on detail.billOfBuyID=main.BillOfBuyID '
set @pSql=@pSql+' where main.status=1 and (year(detail.BuyDate)='+@PcurYear+' and (month(detail.BuyDate)>='+convert(varchar(50),@PstartMonth)+' and month(detail.BuyDate)<='+convert(varchar(50),@PendMonth)+')) '

if(@PproID<>0)
set @pSql=@pSql+' and goodsID='+convert(varchar(50),@PproID)

set @pSql=@pSql+' group by CustomerID'
set @pSql=@pSql+' )C1 '

set @pSql=@pSql+' ON G.CustomerID=C1.CustomerID '

set @pSql=@pSql+' left join '
set @pSql=@pSql+'('
set @pSql=@pSql+'select CustomerID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfBuy detail join tBillOfBuy main on detail.billOfBuyID=main.BillOfBuyID '
set @pSql=@pSql+' where  main.status=1 and  (year(detail.BuyDate)='+@PlastYear+' and (month(detail.BuyDate)>='+convert(varchar(50),@PstartMonth)+' and month(detail.BuyDate)<='+convert(varchar(50),@PendMonth)+'))  '

if(@PproID<>0)
set @pSql=@pSql+' and goodsID='+convert(varchar(50),@PproID)

set @pSql=@pSql+' group by CustomerID'
set @pSql=@pSql+' )C2 '

set @pSql=@pSql+' ON G.CustomerID=C2.CustomerID'


--print @pSql

set nocount off
exec(@pSql)
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：显示上报的产品销售情况列表

参数：
	@pBeginDate 统计起始日期
	@pEndDate 统计结束日期
	@pProClassID 统计货物所属分类 ； 0为不指定分类

输出：显示出某段时间内，产品的销售统计情况。
*/
CREATE PROCEDURE [Storage].[sp_CalCheckinProList]
(
@pBeginDate varchar(20),
@pEndDate varchar(20),
@pProClassID int=0
) AS

Begin
	SET NOCOUNT ON
	BEGIN TRAN
	
	declare @CheckinReportID int -- 建立统计表主表并获取数据
	declare @RootCustomerID int --循环读取客户时记录的ID
	insert into tCheckinReport (ProClassID,BeginDate,EndDate) values (@pProClassID,@pBeginDate,@pEndDate)
	set @CheckinReportID=@@identity
	--已经得到主ID，下面建立子表数据，将统计的记录插入到子表中
	

	if @@ERROR!=0 goto Err_Proc


	declare tCalCheckinProList_cursor  Cursor for	--建立游标

	select CustomerID from  tCustomer  where CustType=1 order by CustomerID asc
	open tCalCheckinProList_cursor

		fetch next  from tCalCheckinProList_cursor into @RootCustomerID
		 --使用游标，遍历所有需要上报的客户；并与下面的统计结果对应，将单品的统计结果归属到每一位上报客户列表中。
		while(@@fetch_status=0)
		begin
			if(@RootCustomerID!=null)
			begin


--根据查询条件，将统计结果显示出来

	insert into TCalCheckinReportData (CheckinReportID,SellerName,CustomerName,GoodsName,BuyNums,BuyPrice,BuyMoney,BatchNO)

	
		select @CheckinReportID as CheckinReportID,SellerName,tCustomer.shortName as CustomerName,TGoods.GoodsName,(FactSellNums)BuyNums,BuyPrice,(FactSellNums*BuyPrice)BuyMoney,batchNo

		from
		(
		    (
			select sellTable.CustomerID,sellTable.ProcID,(SellNums-isnull(CancelNums,0))FactSellNums,SellNums,BuyMoney,isnull(CancelNums,0)CancelNums,isnull(CancelMoney,0)CancelMoney from 
			(
				--针对指定的上报客户，与其他客户的对应关系，将相应客户的销售数据进行统计
				select   @RootCustomerID as CustomerID,ProcID,sum(SellNums)SellNums,sum(BuyMoney)BuyMoney from vwsell where  (goodsTypeID in (select DataID from storage.fnGetBaseDataTreeTable(@pProClassID,2)))   and   (SellDate>=@pBeginDate and SellDate<=@pEndDate) and ((customerID in (select SubCustomerID as CustomerID from tCustomerRelation where CheckinReportID=0 and RootCustomerID=@RootCustomerID)) or (customerID=@RootCustomerID)) group by ProcID 
			) sellTable left join
			(
				--针对指定的上报客户，与其他客户的对应关系，将相应客户的退货数据进行统计
				select  @RootCustomerID as  CustomerID,ProcID,sum(CancelNums)CancelNums,sum(CancelMoney)CancelMoney from vwsellBack where   (goodsTypeID in (select DataID from storage.fnGetBaseDataTreeTable(@pProClassID,2)))   and  (CancelDate>=@pBeginDate and CancelDate<=@pEndDate) and ((customerID in (select SubCustomerID as CustomerID from tCustomerRelation  where CheckinReportID=0 and RootCustomerID=@RootCustomerID)) or (customerID=@RootCustomerID)) group by  ProcID
			) CancelSellTable
			on sellTable.CustomerID=CancelSellTable.CustomerID and sellTable.ProcID=CancelSellTable.ProcID

			)

		) SellData 

	join

	TGoods on SellData.ProcID=TGoods.GoodsID 

	join

	tCustomer on SellData.CustomerID=tCustomer.CustomerID

	join 
	(
		select distinct GoodsID as ProcID,storage.fnGetMaxBatchNo(GoodsID)as batchNo from tDetailOfPutin
	) BatchNoList

	on BatchNoList.ProcID=SellData.ProcID

	join
	(

	select top 1 storage.fnGetNewestSeller(isnull(tCustomerRelation.SubCustomerID,@RootCustomerID))SellerName,@RootCustomerID as CustomerID 
	
	from (select * from tCustomerRelation where tCustomerRelation.CheckinReportID=0  and  tCustomerRelation.RootCustomerID=@RootCustomerID ) tCustomerRelation 
	
	 right join  tBillOfSell on tCustomerRelation.SubCustomerID=tBillOfSell.CustomerID
	 where tBillOfSell.status=1


	) SellerData

	on SellData.CustomerID=SellerData.CustomerID


	 order by SellData.ProcID ASC


	--显示完毕










	if @@ERROR!=0 goto Err_Proc




fetch next  from tCalCheckinProList_cursor into @RootCustomerID


		end
	end
		
	close tCalCheckinProList_cursor
	deallocate tCalCheckinProList_cursor







	if @@ERROR!=0 goto Err_Proc

	--统计数据已经插入完成，则将未归列的客户关系数据，归属到某个统计ID上

	update  tCustomerRelation  set CheckinReportID=@CheckinReportID where CheckinReportID=0
	



	--子表数据增加完成
	if @@ERROR!=0 goto Err_Proc

	commit tran
	set nocount off
	return 0

Err_Proc:
	rollback tran
	set nocount off

	return -1

End
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	根据返点设置，计算所有的客户指定时间段内的返点额，并写入客户返点表（tPayRakeOff）

参数：
	@pCustomerIDS	varchar(8000)	多个客户ID组成的字串（逗号分隔），如果为空，表示所有的客户
	@pYear		int		年份
	@pStartDate	varchar(20)		开始日期
	@pEndDate	varchar(20)		结束日期

返回：
	0	成功
	-1	失败
	-2	无该年份通用基本定额设置数据
	-3	无该年份通用超额返点率设置数据

基本算法：
　1、每个客户每年都有一个销售基本总额，当当年达到这个基本总额时，按这个总额*基本返点率返点；（A）
　2、超出基本总额部分，按“销售返点设置表[tRakeOff]”中的符合条件的梯级的返点率*超额金额返点；（B）
　3、客户当年的返点总额 = A+B
*/
CREATE  PROCEDURE [storage].[sp_CalRakeOff]
(
	@pCustomerIDS	varchar(8000),	--多个客户ID组成的字串（逗号分隔），如果为空，表示所有的客户
	@pYear		int,		--年份
	@pStartDate	varchar(20),		--开始日期
	@pEndDate	varchar(20)		--结束日期
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(8000)
	declare @strSQL1 varchar(8000)
	declare @CommTotalMoney numeric(18,2)
	declare @CommBaseRate numeric(18,2)
	declare @i int
	declare @iReturn int

	set @iReturn = -1

	/*create table #tmpCustomer(
		CustomerID	numeric	not null,
		CountAllMoney	numeric(20,8) not null,	--万元
		BaseMoney	numeric(20,8) not null,	--万元
		BaseRate	numeric(20,8) not null,
		RakeOffMoney	numeric(20,8)		--返点金额
	)*/

	--获取该年份通用基本定额
	select
		@CommTotalMoney = TotalMoney,
		@CommBaseRate = BaseRate
	from
		tCommYearTaskMoney
	where
		[Year] = @pYear

	if(@CommTotalMoney is null) begin
		set @iReturn = -2
		goto Err_Proc	--无该年份通用基本定额设置数据
	end

	select
		@i = count(RakeOffID)
	from
		tCommRakeOff
	where
		[Year] = @pYear

	if(@i <= 0) begin
		set @iReturn = -3
		goto Err_Proc	--无无该年份通用超额返点率设置数据
	end


	--清除已有的该年份的返点记录(tPayRakeOff)
	set @strSQL = '
	delete from 
		tPayRakeOff 
	where
		[Year] = ''' +  convert(varchar(20),@pYear) + ''''
	if(@pCustomerIDS <> '') begin
		set @strSQL = @strSQL + ' and CustomerID in(' + @pCustomerIDS + ')'
	end
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--计算这些客户的销售额（只有有销售额的客户才计算返点）
	set @strSQL1 = '
	--insert into #tmpCustomer
	select
		CustomerID,
		sum(CountAllMoney)/10000 as CountAllMoney
	from
		tBillOfSell
	where
		SellDate between ''' + convert(varchar(20),@pStartDate) + ''' and ''' +  convert(varchar(20),@pEndDate) + '''
		and Status > 0
		'
	if(@pCustomerIDS <> '') begin
		set @strSQL = @strSQL + ' and CustomerID in(' + @pCustomerIDS + ')'
	end
	set @strSQL1 = @strSQL1 + ' group by CustomerID'
	--exec(@strSQL1)
	--select * from #tmpCustomer

	--获取指定的这些客户(@pCustomerIDS)的该年份的返点设置数据
--方法：先从客户任务额设置（tYearTaskMoney）和客户销售返点设置（tRakeOff）中取数据，如果有，则取出；如果没有，则从通用任务额设置（tCommYearTaskMoney）和通用销售返点设置（tCommRakeOff）中取数据
--出错：[该年份没有返点任务额设置数据]
--　　　如果没有返点设置，则按任务额标准计算多余销售额的返点金额

	--根据这些客户的返点设置数据和销售额，计算返点金额
	--写入这些客户的返点金额
	set @strSQL = '
	insert into tPayRakeOff(
			CustomerID,
			Year,
			StartDate,
			EndDate,
			BaseMoney,
			SellMoney,
			Rate,
			RakeoffMoney
			)
	select
		CustomerID,
		' + convert(varchar(20),@pYear) + ',
		''' + @pStartDate + ''',
		''' + @pEndDate + ''',
		BaseMoney,
		CountAllMoney,
		BaseRate,
		(case when CountAllMoney>=BaseMoney then BaseMoney*10000*BaseRate/100 else 0  end + case when CountAllMoney>BaseMoney then Storage.fnCalRakeOff(' + convert(varchar(20),@pYear) + ',CustomerID,CountAllMoney-BaseMoney) else 0 end) as RakeOffMoney
	from (
	select
		c.CustomerID,
		c.CountAllMoney,
		isnull(r.TotalMoney,' + convert(varchar(20),@CommTotalMoney) + ') BaseMoney,
		isnull(r.BaseRate,' + convert(varchar(20),@CommBaseRate) + ') BaseRate
	from
		(' + @strSQL1 + ') c
		--#tmpCustomer c
	LEFT OUTER JOIN
	(select
		CustomerID,
		TotalMoney,
		BaseRate
	from
		tYearTaskMoney
	where
		[Year] = ' + convert(varchar(20),@pYear)
	if(@pCustomerIDS <> '') begin
		set @strSQL = @strSQL + ' and CustomerID in(' + @pCustomerIDS + ')'
	end
	set @strSQL = @strSQL + ') r
	 ON c.CustomerID = r.CustomerID'

	set @strSQL = @strSQL + ') a'
	exec(@strSQL)
OK_Proc:
	commit tran
	--drop table #tmpCustomer
	set nocount off
	return 0
Err_Proc:
	rollback tran
	--drop table #tmpCustomer
	set nocount off
	return @iReturn
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO



/*
功能：根据年份、月份时间区间，以及产品的分类查询出产品的销售情况
	包括销售的数量，销售额，与同期比较的差额、差率
输入参数：
		@PstartDate=启始时间 eg:2006-1-1
		@PendDate=终止时间 eg:2006-6-30
		@PproClassID=指定的产品分类ID
		@PproID=指定的产品ID
		@PdeptID=指定店铺ID
		@CompID=公司ID
	
*/

CREATE   PROCEDURE [Storage].[sp_CalSellProduct]

@PstartDate varchar(50),
@PendDate varchar(50),
@PproClassID int = 0,
@PproID int = 0,
@PdeptID int=0,
@CompID int

 AS

set nocount on

declare @GoodsType varchar(50 )
declare @pSql varchar(4000)
declare @pSqlCondition varchar(200)

set @GoodsType = '2'	--产品类型 0-产品 1-半成品 2-产品(成品)

set @pSql='select G.GoodsID,G.GoodsCode,G.goodsname,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0)))SellNums,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0)))SellMoney'
set @pSql=@pSql+' from ( '

set @pSql=@pSql+' SELECT  *  FROM TGoods  WHERE  GoodsType='+@GoodsType+'  '

if(@PproClassID!=0)
    set @pSql=@pSql+' AND GoodsTypeID in ('+storage.fnGetBaseDataClassStr(convert(varchar(50),@PproClassID),0,2)+')  '

if(@PproID!=0)
   set @pSql=@pSql+' AND GoodsID='+convert(varchar(50),@PproID)+'  '


set @pSql=@pSql+' ) G '


set @pSql=@pSql+'  left join '
set @pSql=@pSql+' ( '

set @pSql=@pSql+'  select SellData.procID,(resultMoney-isnull(cancelmoney,0))resultMoney,(resultNums-isnull(cancelNums,0))resultNums  from '
set @pSql=@pSql+' ( '
set @pSql=@pSql+'select procID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfSell a join tBillOfSell b on a.BillOfSellID=b.BillOfSellID  '
set @pSql=@pSql+' where  CompID='+convert(varchar(50),@CompID)+' and b.status=1 and  a.selldate>='''+@PstartDate+''' and  a.selldate<='''+@PendDate+'''  '


if @PdeptID!=0
set @pSql=@pSql+' and b.DeptID='+convert(varchar(50),@PdeptID)

set @pSql=@pSql+' group by procID '


set @pSql=@pSql+' )SellData  '
set @pSql=@pSql+'left join  '
set @pSql=@pSql+' ( '
set @pSql=@pSql+' select procID,sum(cancelmoney)cancelmoney,sum(cancelnums)cancelnums from tDetailOfSellBack a join tSellBack b on a.SellBackID=b.SellBackID '
set @pSql=@pSql+' where CompID='+convert(varchar(50),@CompID)+' and b.status=1 and  a.cancelDate>='''+@PstartDate+''' and  a.cancelDate<='''+@PendDate+'''  group by procID '
set @pSql=@pSql+' )CancelData  '
set @pSql=@pSql+'  on  SellData.procID= CancelData.procID '


set @pSql=@pSql+' ) C1 '
set @pSql=@pSql+' on G.GoodsID=C1.procID order by  SellMoney DESC'


--print @pSql

set nocount off
exec(@pSql)


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*
功能： 统计不同区域的产品在某一时间段内的销售情况
输入参数：当前年份、上一年份、启始月份、终止月份
*/

CREATE  PROCEDURE [Storage].[sp_CalSellProductOfArea]

@PstartDate varchar(50), --启始日期
@PendDate varchar(50), --终止日期
@areaID int = 0,  --区域ID，默认为0
@PproID int= 0 --指定的产品ID
 AS

--创建临时表
create table #tmpResult (
areaID int,
areaName varchar(200),
SellNums  varchar(200),
SellMoney  varchar(200)
)

set nocount on
declare @tmpClassID int

if(@PproID=0)

begin

--统计所有产品的信息

declare tArea_cursor  Cursor for

select  areaID  from storage.fnGetTreeAreaTable(@areaID,0,0)

open tArea_cursor

fetch next  from tArea_cursor into @tmpClassID  --获取当前的区域ID


			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin


----------------------------------------------------------------------------------------------------------------
--将统计得到的数据插入到临时表中
insert into #tmpResult  (areaID,areaName,SellNums,SellMoney)
(
select G.areaID,Storage.fnGetParentAreaStr(G.areaID) as areaName,

(convert(varchar(50),isnull(C1.resultNums,0)))SellNums,
(convert(varchar(50),isnull(C1.resultMoney,0)))SellMoney

	 from (select * from tArea  where areaID=@tmpClassID ) G  

	join 
	(
	select SellData.areaID,(resultMoney-isnull(cancelMoney,0))resultMoney,(resultNums-isnull(cancelNums,0))resultNums    from
	(
	select @tmpClassID areaID, sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfSell detail join tBillOfSell main on detail.billOfSellID=main.BillOfSellID 
	 where main.status=1   and  detail.selldate>=@PstartDate    and  detail.selldate<=@PendDate
	and areaID in (select areaID from storage.fnGetTreeAreaTable(@tmpClassID,0,0))
	) SellData
	left join
	(
	select  @tmpClassID areaID,sum(CancelMoney)CancelMoney,sum(CancelNums)CancelNums from tDetailOfSellBack a join tSellBack b on a.sellBackID=b.sellBackID 
	where b.status=1 and a.CancelDate>=@PstartDate  and  a.CancelDate<=@PendDate
	and areaID in (select areaID from storage.fnGetTreeAreaTable(@tmpClassID,0,0))
	)CancelData

	on SellData.areaID=CancelData.areaID 

	 ) C1

	 on G.areaID=C1.areaID 

	)

-------------------------------------------------------------------------------------------------------------








	fetch next  from tArea_cursor into @tmpClassID    --获取当前的区域ID
				end
			end

			close tArea_cursor
		deallocate tArea_cursor

end







else








begin

--统计某个指定产品的信息

declare tArea_cursor  Cursor for

select  areaID  from storage.fnGetTreeAreaTable(@areaID,0,0)

open tArea_cursor

fetch next  from tArea_cursor into @tmpClassID  --获取当前的区域ID


			while(@@fetch_status=0)
			begin
				if(@tmpClassID!=null)
				begin


----------------------------------------------------------------------------------------------------------------
--将统计得到的数据插入到临时表中
insert into #tmpResult  (areaID,areaName,SellNums,SellMoney)
(
select G.areaID,Storage.fnGetParentAreaStr(G.areaID) as areaName,

(convert(varchar(50),isnull(C1.resultNums,0)))SellNums,
(convert(varchar(50),isnull(C1.resultMoney,0)))SellMoney


	 from (select * from tArea  where areaID=@tmpClassID ) G  

	join 
	(
	select SellData.areaID,(resultMoney-isnull(cancelMoney,0))resultMoney,(resultNums-isnull(cancelNums,0))resultNums    from
	(
	select @tmpClassID areaID, sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfSell detail join tBillOfSell main on detail.billOfSellID=main.BillOfSellID 
	 where main.status=1 and procID=@PproID and  detail.selldate>=@PstartDate    and detail.selldate<=@PendDate
	and areaID in (select areaID from storage.fnGetTreeAreaTable(@tmpClassID,0,0))
	) SellData
	left join
	(
	select  @tmpClassID areaID,sum(CancelMoney)CancelMoney,sum(CancelNums)CancelNums from tDetailOfSellBack a join tSellBack b on a.sellBackID=b.sellBackID 
	where b.status=1 and procID=@PproID  and a.CancelDate>=@PstartDate  and  a.CancelDate<=@PendDate
	and areaID in (select areaID from storage.fnGetTreeAreaTable(@tmpClassID,0,0))
	)CancelData

	on SellData.areaID=CancelData.areaID

	 ) C1

	 on G.areaID=C1.areaID

	
	)

-------------------------------------------------------------------------------------------------------------








	fetch next  from tArea_cursor into @tmpClassID    --获取当前的区域ID
				end
			end

			close tArea_cursor
		deallocate tArea_cursor





end

set nocount off

select  * from #tmpResult  order by SellMoney DESC

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO



/*
功能：根据年份、月份时间区间，查询出不同客户对产品的消费情况
	包括销售的数量，销售额，与同期比较的差额、差率
输入参数：
		@PstartDate=启始时间  eg:2006-1-1
		@PendDate=截止时间  eg:2006-6-30
		@PcustomerID=指定的业务员
		@PproID int=0 --指定某个产品的ID
		@PdeptID int=0 --指定某个店面的ID
		@CompID=公司ID
	
*/

CREATE   PROCEDURE [Storage].[sp_CalSellProductOfCustomer]

@PstartDate varchar(50),
@PendDate  varchar(50),
@PcustomerID int=0, --默认为不指定客户ID，则显示所有客户的消费情况
@PproID int=0, --指定某个产品的ID
@PdeptID int=0, --指定某个店面的ID
@CompID int

 AS

set nocount on

declare @GoodsType varchar(50 )
declare @pSql varchar(4000)



set @pSql='select G.CustomerID,CustNO,ShortName,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultNums,0)))SellNums,'
set @pSql=@pSql+'(convert(varchar(50),isnull(C1.resultMoney,0)))SellMoney '
set @pSql=@pSql+' from (select * from tCustomer where CompID='+convert(varchar(50),@CompID)+' '
	if(@PcustomerID!=0)
	set @pSql=@pSql+' and CustomerID='+convert(varchar(50),@PcustomerID)

set @pSql=@pSql+'  ) G '
set @pSql=@pSql+' left join '
set @pSql=@pSql+'('

set @pSql=@pSql+' select SellData.CustomerID,(resultMoney-isnull(cancelMoney,0))resultMoney,(resultNums-isnull(cancelNums,0))resultNums from '
set @pSql=@pSql+'('

set @pSql=@pSql+'select CustomerID,sum(factmoney-cancelmoney)resultMoney,sum(nums-cancelnums)resultNums from tDetailOfSell detail join tBillOfSell main on detail.billOfSellID=main.BillOfSellID '
set @pSql=@pSql+' where main.status=1 and  detail.selldate>='''+@PstartDate+''' and  detail.selldate<='''+@PendDate+'''   '

if @PdeptID!=0
set @pSql=@pSql+' and deptID='+convert(varchar(50),@PdeptID)

if(@PproID<>0)
set @pSql=@pSql+' and procID='+convert(varchar(50),@PproID)

set @pSql=@pSql+'  group by CustomerID'

set @pSql=@pSql+')SellData '

set @pSql=@pSql+'left join '

set @pSql=@pSql+'('
set @pSql=@pSql+'select b.CustomerID,sum(a.CancelMoney)CancelMoney,sum(a.CancelNums)CancelNums from tDetailOfSellBack a join tSellBack b on a.SellBackID=b.SellBackID '
set @pSql=@pSql+'  where  b.status=1 and  a.canceldate>='''+@PstartDate+''' and a.canceldate<='''+@PendDate+'''  '

if(@PproID<>0)
set @pSql=@pSql+' and procID='+convert(varchar(50),@PproID)

set @pSql=@pSql+'   group by CustomerID '
set @pSql=@pSql+' )CancelData'
	
set @pSql=@pSql+' on SellData.CustomerID=CancelData.CustomerID '



set @pSql=@pSql+' )C1 '

set @pSql=@pSql+' ON G.CustomerID=C1.CustomerID  order by SellMoney DESC'



--print @pSql

set nocount off
exec(@pSql)


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
GO




CREATE    PROCEDURE [storage].[sp_CalSellProductOfSeller]
/*
功能：根据年份、月份时间区间，以及产品的分类查询出不同业务员对产品的销售情况
	包括销售的数量，销售额，与同期比较的差额、差率
输入参数：
		@PstartDate=启始日期 eg:2006-1-1
		@PendDate=终止日期 eg:2006-6-30
		@PsellerID=指定的业务员
		@CustomerID=指定的客户ID
		@CompID=公司ID
	
*/

@PstartDate varchar(50),
@PendDate varchar(50),
@PsellerID int=0, --为0时为不指定业务员
@CustomerID int =0,  --为0时为不指定客户
@DeptID int=0, --为0时为不指定部门
@CompID int

 AS

set nocount on

declare @GoodsType varchar(50 )
declare @pSql varchar(4000)
declare @pSqlCondition varchar(200)


set @pSql='select Emp.empID,Emp.empNo,Emp.empName,tDepartment.DeptName,'
set @pSql=@pSql+'isnull(SellPay.PayMoney,0) sellMoney  '

set @pSql=@pSql+' from (select * from tEmployee where type=1 and CompID='+convert(varchar(50),@CompID)+' '

if @DeptID!=0
  set @pSql=@pSql+'  and DeptID='+convert(varchar(50),@DeptID) --指定显示某一部分的所有业务员

if @PsellerID!=0
   set @pSql=@pSql+' and empID='+convert(varchar(50),@PsellerID) 	--指定显示某一业务员的统计信息

set @pSql=@pSql+'  ) Emp '

set @pSql=@pSql+' left join ( '

set @pSql=@pSql+' select empID,sum(PayMoney)PayMoney  from vwSellPay where  type=0 '

set @pSql=@pSql+' and CheckTime>='''+@PstartDate+''' and CheckTime<='''+@PendDate+'''   '

if @CustomerID!=0
   set @pSql=@pSql+'  and  CustomerID='+convert(varchar(50),@CustomerID) --指定某个客户

set @pSql=@pSql+'  group by EmpID  ) SellPay '

set @pSql=@pSql+' on Emp.empID=SellPay.empID '

set @pSql=@pSql+' join tDepartment on Emp.DeptID=tDepartment.DeptID   order by SellMoney DESC'


--print @pSql

set nocount off
exec(@pSql)




GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	修改用户密码。 

参数：
	@pEmpID	员工ID
	@pOldPwd	旧密码
	@pNewPwd	新密码

返回：
	-1	失败
	-2	旧密码错误
	0	修改成功
*/

CREATE  PROCEDURE [storage].[sp_ChangePassword]
(
	@pEmpID numeric,
	@pOldPwd varchar(100) ,
	@pNewPwd varchar(100) 
)
 AS
BEGIN
	--if getdate() > convert(datetime,'2004-5-1')
	--	return
	set nocount on
	declare @OldPwd varchar(100)
	declare @Enabled int
	declare @RetValue int

	set @RetValue = -1

	select @OldPwd = [Password] from tEmployee where EmpID = @pEmpID
	if @@ERROR != 0 goto Err_Proc

	if (@OldPwd != null)
	begin
		if (@OldPwd != @pOldPwd)
			set @RetValue = -2
		else begin
			update tEmployee set [Password] = @pNewPwd where EmpID = @pEmpID
			if @@ERROR != 0 goto Err_Proc
			set @RetValue = 0
		end
	end

OK_Proc:
	set nocount off
	return @RetValue
Err_Proc:
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	检验用户登录的合法性。 

参数：
	@pAccount	帐号
	@pPwd	密码

返回：
	-1	失败
	0	已禁用
	>0	账号的ID
*/

CREATE  PROCEDURE [storage].[sp_CheckLogin]
(
	@pAccount varchar(100),
	@pPwd varchar(100) 
)
 AS
BEGIN
	--if getdate() > convert(datetime,'2004-5-1')
	--	return
	set nocount on
	declare @EmpID numeric
	declare @Enabled int
	declare @RetValue int

	set @RetValue = -1

	if(@pAccount !='' and @pPwd !='')
	begin
		declare @strSQL varchar(1000)
		select @EmpID=[EmpID],@Enabled=EnabledFlag from tEmployee where [Account]=@pAccount and [Password]=@pPwd

		if(@EmpID = null)
			set @RetValue = -1
		else if(@Enabled = 0)
			set @RetValue = 0
		else
			set @RetValue = @EmpID
	end

	set nocount off
	return @RetValue
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	审核指定的多笔调拨单。

参数：
	@pIDS	varchar(8000)		多笔调拨单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)	审核人

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_CheckMutiBillOfExchange]
(
	@pIDS varchar(8000),	--多笔调拨单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)
) AS
BEGIN
	SET NOCOUNT ON

    IF(@pIDS != '') BEGIN
	declare @strSQL varchar(8000)
	/*BEGIN TRAN
	declare @strSQL varchar(8000)
	declare @StoreHouseID numeric
	declare @GoodsID numeric
	declare @OutNums numeric(12,2)
	declare @AllMoney numeric(12,2)
	declare @DetailID numeric
	declare @PutinDetailID numeric
	declare @HasNums numeric(12,2)
	declare @PutinNums numeric(12,2)
	declare @DecNums numeric(12,2)
	declare @BatchNO varchar(12)
	declare @TakeoutBatchNO varchar(12)
	--declare @TmpTime datetime

	--出库单明细按库房和货品汇总表
	create table #tGoods(
		StoreHouseID numeric not null,
		GoodsID numeric not null,
		OutNums numeric(12,2) not null,
		AllMoney numeric(12,2) not null
	)

	--出库单明细表
	create table #tDetailOfTakeout(
		DetailID numeric not  null,
		StoreHouseID numeric not null,
		GoodsID numeric not null,
		OutNums numeric(12,2) not null,
		AllMoney numeric(12,2) not null,
		BatchNO varchar(50)
	)

	--库房货品库存明细
	create table #tDetailOfPutin(
		DetailID numeric not null,
		PutinNums numeric(12,2) not null,
		BatchNO varchar(50),
		MadeDate datetime,
		PutinTime datetime
	)

	--库房货品库存明细
	create table #tDetailOfPutinSort(
		DetailID numeric not null,
		PutinNums numeric(12,2) not null,
		BatchNO varchar(50)
	)

	--获取这些出库单明细
	set @strSQL = '
	insert into #tDetailOfTakeout
	select
		DetailID,
		StoreHouseID,
		GoodsID,
		OutNums,
		AllMoney,
		isnull(BatchNO,'''')
	from
		tDetailOfTakeout
	where
		BillOfTakeoutID in(' + @pIDS + ')
		and Status = 0
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--统计出每个产品在每个仓库中的出库数量和出库金额
	insert into #tGoods
	select
		StoreHouseID,
		GoodsID,
		sum(OutNums) OutNums,
		sum(AllMoney) AllMoney
	from
		#tDetailOfTakeout
	group by
		StoreHouseID,
		GoodsID
	if @@ERROR != 0 goto Err_Proc

	--更改明细中每个产品的实际库存量（tGoods）
	set @strSQL = '
	update g 
		set CurStoreNums=CurStoreNums - bill.OutNums
	from tGoods g,
	(select
		d.GoodsID,sum(d.OutNums) OutNums
	from
		#tGoods d
	group by
		d.GoodsID) bill
	where
		bill.GoodsID = g.GoodsID'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc


	--更改产品库存表中已存在的每个产品的实际库存量及金额
	set @strSQL = '
	update SN 
		set SN.CurStoreNums=SN.CurStoreNums-bill.OutNums,
		SN.AllMoney = SN.AllMoney - bill.AllMoney
	from 
		tProductStoreNums SN,
		#tGoods bill
	where
		bill.GoodsID = SN.GoodsID
		and bill.StoreHouseID = SN.StoreHouseID
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--更改（新增）产品库存表中不存在的每个产品的实际库存量及金额
	set @strSQL = '
	insert into tProductStoreNums(StoreHouseID, GoodsID, CurStoreNums, AllMoney)
	select
		bill.StoreHouseID,
		bill.GoodsID,
		0-bill.OutNums,
		0-bill.AllMoney
	from 
		#tGoods bill
	where
		not exists(
			select SN.GoodsID 
			from tProductStoreNums SN 
			where bill.GoodsID = SN.GoodsID and  bill.StoreHouseID = SN.StoreHouseID)
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--2006-06-06 Added By LiuYong -------------------------------------------------------------------------------------------------------------------
	--从入库单明细中按先入先的原则扣减数量及金额
		
	--建立出库单明细游标
	Declare TakeoutCursor Cursor for
		SELECT
			DetailID,
			StoreHouseID,
			GoodsID,
			OutNums,
			AllMoney,
			BatchNO
		FROM
			#tDetailOfTakeout
	For Read Only
		
	Open TakeoutCursor
		
	Fetch Next
		From TakeoutCursor
		Into @DetailID,@StoreHouseID,@GoodsID,@OutNums,@AllMoney,@TakeoutBatchNO
		
	while (@@Fetch_Status = 0)
	begin
		--读取数据
		set @HasNums = @OutNums	--剩余数量

		delete from #tDetailOfPutin
		delete from #tDetailOfPutinSort

		insert into #tDetailOfPutin
			select
				DetailID,
				HasNums,	--PutinNums,
				BatchNO,
				MadeDate,
				PutinTime
			from
				tDetailOfPutin
			where
				GoodsID = @GoodsID
				and HasNums > 0
				and Status = 1
				and StoreHouseID = @StoreHouseID

		insert into #tDetailOfPutinSort
		select DetailID, PutinNums,BatchNO  from #tDetailOfPutin where BatchNO = @TakeoutBatchNO order by MadeDate asc, PutinTime asc

		insert into #tDetailOfPutinSort
		select DetailID, PutinNums,BatchNO  from #tDetailOfPutin where BatchNO <> @TakeoutBatchNO order by MadeDate asc, PutinTime asc

		--建立指定库房和货品的入库单明细游标
		Declare PutinCursor Cursor for
			select *  from #tDetailOfPutinSort
		For Read Only

		Open PutinCursor

		Fetch Next
			From PutinCursor
			Into @PutinDetailID,@PutinNums,@BatchNO

		while (@@Fetch_Status = 0)
		begin
			--如果扣减完成
			if(@HasNums <= 0)
				break

			if(@PutinNums >= @HasNums)		--如果够扣减，则直接扣减该出库数量
				set @DecNums = @HasNums
			else
				set @DecNums = @PutinNums--如果不够扣减，则把该入库数量扣减掉

			set @HasNums = @HasNums - @DecNums

			--扣减入库单明细
			update

				tDetailOfPutin
			set
				UsedNums = UsedNums + @DecNums,
				HasNums = HasNums - @DecNums
			where
				DetailID = @PutinDetailID

			if (@@ERROR != 0)
			begin
				Close PutinCursor
				Deallocate PutinCursor

				Close TakeoutCursor
				Deallocate TakeoutCursor

				 goto Err_Proc
			end

			--写入出库货物来源于入库货物对应表[tDetailOfTakeoutSource]中
			insert into 
				tDetailOfTakeoutSource
			values
				(@DetailID, @PutinDetailID, @GoodsID, @DecNums, Storage.fnGetGoodsTypeOfGoods(@GoodsID),@BatchNO )

			if (@@ERROR != 0)
			begin
				Close PutinCursor
				Deallocate PutinCursor

				Close TakeoutCursor
				Deallocate TakeoutCursor

				 goto Err_Proc
			end

			Fetch Next From PutinCursor Into @PutinDetailID, @PutinNums,@BatchNO--,@TmpTime,@TmpTime
		end

		Close PutinCursor
		Deallocate PutinCursor

		Fetch Next From TakeoutCursor Into @DetailID,@StoreHouseID,@GoodsID,@OutNums,@AllMoney,@TakeoutBatchNO
	end
	
	Close TakeoutCursor
	Deallocate TakeoutCursor*/
	-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

	--修改出库单为审核状态，更改审核人及审核时间
	set @strSQL = 'update tBillOfExchange set Status = 1, CheckMan=''' + @pCheckMan + ''', CheckTime=getdate() where BillOfExchangeID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--修改明细数据为审核状态
	set @strSQL = 'update tDetailOfExchange set Status=1 where BillOfExchangeID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

OK_Proc:
	/*commit tran
	drop table #tDetailOfPutin
	drop table #tDetailOfTakeout
	drop table #tDetailOfPutinSort
	drop table #tGoods*/
	set nocount off
	return 0
Err_Proc:
	/*rollback tran
	drop table #tDetailOfPutin
	drop table #tDetailOfTakeout
	drop table #tDetailOfPutinSort
	drop table #tGoods
	set nocount off*/
	return -1
    END
    set nocount off

END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	审核指定的多笔入库单。

参数：
	@pIDS	varchar(8000)		多笔入库单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)	审核人

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_CheckMutiBillOfPutin]
(
	@pIDS varchar(8000),	--多笔入库单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)
) AS
BEGIN
	SET NOCOUNT ON
    IF(@pIDS != '') BEGIN
	BEGIN TRAN
	declare @strSQL varchar(8000)
	create table #tGoods(
		StoreHouseID numeric not null,
		GoodsID numeric not null,
		PutinNums numeric(12,2) not null,
		AllMoney numeric(12,2) not null
	)

	--统计出每个产品在每个仓库中的入库数量和入库金额
	set @strSQL = '
	insert into #tGoods
	select
		StoreHouseID,
		GoodsID,
		sum(PutinNums) PutinNums,
		sum(AllMoney) AllMoney
	from
		tDetailOfPutin
	where
		BillOfPutinID in(' + @pIDS + ')
		and Status = 0
	group by
		StoreHouseID,
		GoodsID
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--更改明细中每个产品的实际库存量（tGoods）
	set @strSQL = '
	update g 
		set CurStoreNums=CurStoreNums+bill.PutinNums
	from 
		tGoods g,
		(select 
			d.GoodsID,
			sum(d.PutinNums) PutinNums,
			sum(d.AllMoney) AllMoney
		from 
			#tGoods d 
		group by 
			d.GoodsID) bill
	where
		bill.GoodsID = g.GoodsID'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--更改产品库存表中已存在的每个产品的实际库存量及金额
	set @strSQL = '
	update SN 
		set SN.CurStoreNums=SN.CurStoreNums+bill.PutinNums,
		SN.AllMoney = SN.AllMoney + bill.AllMoney
	from 
		tProductStoreNums SN,
		#tGoods bill
	where
		bill.GoodsID = SN.GoodsID
		and bill.StoreHouseID = SN.StoreHouseID
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--更改产品库存表中不存在的每个产品的实际库存量及金额
	set @strSQL = '
	insert into tProductStoreNums(StoreHouseID, GoodsID, CurStoreNums, AllMoney)
	select
		bill.StoreHouseID,
		bill.GoodsID,
		bill.PutinNums,
		bill.AllMoney
	from 
		#tGoods bill
	where
		not exists(
			select SN.GoodsID 
			from tProductStoreNums SN 
			where bill.GoodsID = SN.GoodsID and  bill.StoreHouseID = SN.StoreHouseID)
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--修改入库单为审核状态，更改审核人及审核时间
	set @strSQL = 'update tBillOfPutin set Status = 1, CheckMan=''' + @pCheckMan + ''', CheckTime=getdate() where BillOfPutinID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--修改明细数据为审核状态
	set @strSQL = 'update tDetailOfPutin set Status=1 where BillOfPutinID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

        OK_Proc:
	commit tran
	set nocount off
	return 0
        Err_Proc:
	rollback tran
	set nocount off
	return -1
    END

    set nocount off

END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	审核指定的多笔出库单。

参数：
	@pIDS	varchar(8000)		多笔出库单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)	审核人

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_CheckMutiBillOfTakeout]
(
	@pIDS varchar(8000),	--多笔出库单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)
) AS
BEGIN
	SET NOCOUNT ON

    IF(@pIDS != '') BEGIN
	BEGIN TRAN
	declare @strSQL varchar(8000)
	declare @StoreHouseID numeric
	declare @GoodsID numeric
	declare @OutNums numeric(12,2)
	declare @AllMoney numeric(12,2)
	declare @DetailID numeric
	declare @PutinDetailID numeric
	declare @HasNums numeric(12,2)
	declare @PutinNums numeric(12,2)
	declare @DecNums numeric(12,2)
	declare @BatchNO varchar(12)
	declare @TakeoutBatchNO varchar(12)
	--declare @TmpTime datetime

	--出库单明细按库房和货品汇总表
	create table #tGoods(
		StoreHouseID numeric not null,
		GoodsID numeric not null,
		OutNums numeric(12,2) not null,
		AllMoney numeric(12,2) not null
	)

	--出库单明细表
	create table #tDetailOfTakeout(
		DetailID numeric not  null,
		StoreHouseID numeric not null,
		GoodsID numeric not null,
		OutNums numeric(12,2) not null,
		AllMoney numeric(12,2) not null,
		BatchNO varchar(50)
	)

	--库房货品库存明细
	create table #tDetailOfPutin(
		DetailID numeric not null,
		PutinNums numeric(12,2) not null,
		BatchNO varchar(50),
		MadeDate datetime,
		PutinTime datetime
	)

	--库房货品库存明细
	create table #tDetailOfPutinSort(
		DetailID numeric not null,
		PutinNums numeric(12,2) not null,
		BatchNO varchar(50)
	)

	--获取这些出库单明细
	set @strSQL = '
	insert into #tDetailOfTakeout
	select
		DetailID,
		StoreHouseID,
		GoodsID,
		OutNums,
		AllMoney,
		isnull(BatchNO,'''')
	from
		tDetailOfTakeout
	where
		BillOfTakeoutID in(' + @pIDS + ')
		and Status = 0
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--统计出每个产品在每个仓库中的出库数量和出库金额
	insert into #tGoods
	select
		StoreHouseID,
		GoodsID,
		sum(OutNums) OutNums,
		sum(AllMoney) AllMoney
	from
		#tDetailOfTakeout
	group by
		StoreHouseID,
		GoodsID
	if @@ERROR != 0 goto Err_Proc

	--更改明细中每个产品的实际库存量（tGoods）
	set @strSQL = '
	update g 
		set CurStoreNums=CurStoreNums - bill.OutNums
	from tGoods g,
	(select
		d.GoodsID,sum(d.OutNums) OutNums
	from
		#tGoods d
	group by
		d.GoodsID) bill
	where
		bill.GoodsID = g.GoodsID'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc


	--更改产品库存表中已存在的每个产品的实际库存量及金额
	set @strSQL = '
	update SN 
		set SN.CurStoreNums=SN.CurStoreNums-bill.OutNums,
		SN.AllMoney = SN.AllMoney - bill.AllMoney
	from 
		tProductStoreNums SN,
		#tGoods bill
	where
		bill.GoodsID = SN.GoodsID
		and bill.StoreHouseID = SN.StoreHouseID
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--更改（新增）产品库存表中不存在的每个产品的实际库存量及金额
	set @strSQL = '
	insert into tProductStoreNums(StoreHouseID, GoodsID, CurStoreNums, AllMoney)
	select
		bill.StoreHouseID,
		bill.GoodsID,
		0-bill.OutNums,
		0-bill.AllMoney
	from 
		#tGoods bill
	where
		not exists(
			select SN.GoodsID 
			from tProductStoreNums SN 
			where bill.GoodsID = SN.GoodsID and  bill.StoreHouseID = SN.StoreHouseID)
	'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--2006-06-06 Added By LiuYong -------------------------------------------------------------------------------------------------------------------
	--从入库单明细中按先入先的原则扣减数量及金额
		
	--建立出库单明细游标
	Declare TakeoutCursor Cursor for
		SELECT
			DetailID,
			StoreHouseID,
			GoodsID,
			OutNums,
			AllMoney,
			BatchNO
		FROM
			#tDetailOfTakeout
	For Read Only
		
	Open TakeoutCursor
		
	Fetch Next
		From TakeoutCursor
		Into @DetailID,@StoreHouseID,@GoodsID,@OutNums,@AllMoney,@TakeoutBatchNO
		
	while (@@Fetch_Status = 0)
	begin
		--读取数据
		set @HasNums = @OutNums	--剩余数量

		delete from #tDetailOfPutin
		delete from #tDetailOfPutinSort

		insert into #tDetailOfPutin
			select
				DetailID,
				HasNums,	--PutinNums,
				BatchNO,
				MadeDate,
				PutinTime
			from
				tDetailOfPutin
			where
				GoodsID = @GoodsID
				and HasNums > 0
				and Status = 1
				and StoreHouseID = @StoreHouseID

		insert into #tDetailOfPutinSort
		select DetailID, PutinNums,BatchNO  from #tDetailOfPutin where BatchNO = @TakeoutBatchNO order by MadeDate asc, PutinTime asc

		insert into #tDetailOfPutinSort
		select DetailID, PutinNums,BatchNO  from #tDetailOfPutin where BatchNO <> @TakeoutBatchNO order by MadeDate asc, PutinTime asc

		--建立指定库房和货品的入库单明细游标
		Declare PutinCursor Cursor for
			select *  from #tDetailOfPutinSort
		For Read Only

		Open PutinCursor

		Fetch Next
			From PutinCursor
			Into @PutinDetailID,@PutinNums,@BatchNO

		while (@@Fetch_Status = 0)
		begin
			--如果扣减完成
			if(@HasNums <= 0)
				break

			if(@PutinNums >= @HasNums)		--如果够扣减，则直接扣减该出库数量
				set @DecNums = @HasNums
			else
				set @DecNums = @PutinNums--如果不够扣减，则把该入库数量扣减掉

			set @HasNums = @HasNums - @DecNums

			--扣减入库单明细
			update

				tDetailOfPutin
			set
				UsedNums = UsedNums + @DecNums,
				HasNums = HasNums - @DecNums
			where
				DetailID = @PutinDetailID

			if (@@ERROR != 0)
			begin
				Close PutinCursor
				Deallocate PutinCursor

				Close TakeoutCursor
				Deallocate TakeoutCursor

				 goto Err_Proc
			end

			--写入出库货物来源于入库货物对应表[tDetailOfTakeoutSource]中
			insert into 
				tDetailOfTakeoutSource
			values
				(@DetailID, @PutinDetailID, @GoodsID, @DecNums, Storage.fnGetGoodsTypeOfGoods(@GoodsID),@BatchNO )

			if (@@ERROR != 0)
			begin
				Close PutinCursor
				Deallocate PutinCursor

				Close TakeoutCursor
				Deallocate TakeoutCursor

				 goto Err_Proc
			end

			Fetch Next From PutinCursor Into @PutinDetailID, @PutinNums,@BatchNO--,@TmpTime,@TmpTime
		end

		Close PutinCursor
		Deallocate PutinCursor

		Fetch Next From TakeoutCursor Into @DetailID,@StoreHouseID,@GoodsID,@OutNums,@AllMoney,@TakeoutBatchNO
	end
	
	Close TakeoutCursor
	Deallocate TakeoutCursor
	-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

	--修改出库单为审核状态，更改审核人及审核时间
	set @strSQL = 'update tBillOfTakeout set Status = 1, CheckMan=''' + @pCheckMan + ''', CheckTime=getdate() where BillOfTakeoutID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--修改明细数据为审核状态
	set @strSQL = 'update tDetailOfTakeout set Status=1 where BillOfTakeoutID in (' + @pIDS + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

OK_Proc:
	commit tran
	drop table #tDetailOfPutin
	drop table #tDetailOfTakeout
	drop table #tDetailOfPutinSort
	drop table #tGoods
	set nocount off
	return 0
Err_Proc:
	rollback tran
	drop table #tDetailOfPutin
	drop table #tDetailOfTakeout
	drop table #tDetailOfPutinSort
	drop table #tGoods
	set nocount off
	return -1
    END
    set nocount off

END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	审核指定的多张盘点表。

参数：
	@pIDS	varchar(8000)		多张盘点表ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)	审核人

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_CheckMutiCheckTable]
(
	@pIDS varchar(8000),	--多笔出库单ID组成的字串（逗号分隔）
	@pCheckMan varchar(20)
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

--    IF(@pIDS != '') BEGIN
	declare @strSQL varchar(8000)
	declare @BeginDate datetime
	declare @EndDate datetime
	declare @StoreHouseID numeric

	create table #tPutin(
		GoodsID	numeric		not null,
		PutinNums	numeric(12,2)	not null,
		PutinType	int		not null
	)

	create table #tTakeout(
		GoodsID	numeric		not null,
		TakeoutNums	numeric(12,2)	not null,
		TakeoutType	int		not null
	)

	--更改明细中每个产品的实际库存量（tGoods）
	/*set @strSQL = '
	update g 
		set CurStoreNums=CurStoreNums - bill.OutNums
	from tGoods g,
	(select
		d.GoodsID,sum(d.OutNums) OutNums
	from
		tDetailOfTakeout d
	where
		BillOfTakeoutID in(' + @pIDS + ')
		and Status = 0
	group by
		d.GoodsID) bill
	where
		bill.GoodsID = g.GoodsID'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc*/

	--修改出库单为审核状态，更改审核人及审核时间
	set @strSQL = 'update tCheckTable set Status = 1, AuditingMan=''' + @pCheckMan + ''', AuditingTime=getdate() where CheckTableID =' + @pIDS	-- + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--修改明细数据为审核状态
	set @strSQL = 'update tDetailOfCheckTable set Status=1 where CheckTableID = ' + @pIDS	-- + ')'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	--获取盘点表的开始日期和结束日期
	select
		@BeginDate = BeginDate,
		@EndDate = EndDate,
		@StoreHouseID = StoreHouseID
	from
		tCheckTable
	where
		CheckTableID = @pIDS
	if @@ERROR != 0 goto Err_Proc

	--统计入库情况（按库房、产品、入库时间、入库类别统计）
	insert into #tPutin
	select
		GoodsID,
		sum(PutinNums),
		PutinType
	from
		tDetailOfPutin
	where
		StoreHouseID = @StoreHouseID
		and Status = 1
		and PutinTime between @BeginDate and @EndDate
	group by
		GoodsID,
		PutinType
	if @@ERROR != 0 goto Err_Proc

	--统计出库情况（按库房、产品、出库时间、出库类别统计）
	insert into #tTakeout
	select
		GoodsID,
		sum(OutNums),
		TakeoutType
	from
		tDetailOfTakeout
	where
		StoreHouseID = @StoreHouseID
		and Status = 1
		and TakeoutTime between @BeginDate and @EndDate
	group by
		GoodsID,
		TakeoutType
	if @@ERROR != 0 goto Err_Proc

	--写入本期盘点统计表
	---------------------------------------------------------------------------------------------------
	insert into tDetailOfCheckCount
	select 
		D.CheckTableID,
		D.StoreHouseID,
		D.GoodsID,
		isnull(F.FirstNums,0),		--期初数量[FirstNums]
		isnull(P.PutinNums,0),		--本期调入[PutinNums]
		isnull(T.TakeoutNums,0),	--本期发货[TakeoutNums]
		isnull(CC.PutinNums,0),		--客户退货[BackNumsFromCustomer]
		isnull(TC.TakeoutNums,0),	--退回公司[BackNumsToProvider]
		D.FactNums,			--期末数量[LastNums]
		D.Memo
	from
	(select
		CheckTableID,
		StoreHouseID,
		GoodsID,
		FactNums,	--LastNums
		Memo
	from
		tDetailOfCheckTable
	where
		CheckTableID = @pIDS) D

	left outer join tCheckTableFirst F		--期初值
	on
		D.StoreHouseID = F.StoreHouseID
		and D.GoodsID = F.GoodsID

	left outer join #tPutin P			--本期调入
	on
		P.PutinType = 0
		and D.GoodsID = P.GoodsID

	left outer join #tTakeout T		--本期发货
	on
		T.TakeoutType = 0
		and D.GoodsID = T.GoodsID

	left outer join #tPutin CC			--客户退货
	on
		CC.PutinType = 1
		and D.GoodsID = CC.GoodsID

	left outer join #tTakeout TC		--退回公司
	on
		TC.TakeoutType = 1
		and D.GoodsID = TC.GoodsID

	if @@ERROR != 0 goto Err_Proc

	--写入下期期初表
	---------------------------------------------------------------------------------------------------
	--删除原有期初数据
	delete from
		tCheckTableFirst
	where
		exists(
			select DetailID from tDetailOfCheckTable
			where
				CheckTableID = @pIDS
				and StoreHouseID = tCheckTableFirst.StoreHouseID
				and GoodsID = tCheckTableFirst.GoodsID
		)
	if @@ERROR != 0 goto Err_Proc

	--插入期初数据
	insert into tCheckTableFirst
	select
		StoreHouseID,
		GoodsID,
		FactNums,
		CheckDate,
		CheckTableID
	from
		tDetailOfCheckTable
	where
		CheckTableID = @pIDS
	if @@ERROR != 0 goto Err_Proc

--    END
OK_Proc:
	drop table #tPutin
	drop table #tTakeout
	commit tran
	set nocount off
	return 0
Err_Proc:
	drop table #tPutin
	drop table #tTakeout
	rollback tran
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	检测指定中干、指定模块（编号）、指定操作、（加上范围，以便扩展）。
参数：
	@pWorkerNo	varchar(20)		中干编号；
	@pModelID	int			模块ID；
	@pOperator	varchar(20)		操作ID；
	@pRange	varchar(20)
返回：
	0	有权限
	-1	无权限
	-2	系统错误
*/
CREATE PROCEDURE [Storage].[sp_CheckRight](
	@pWorkerNo	varchar(20),
	@pModelID	int,
	@pOperator	varchar(20),
	@pRange	varchar(20)
) AS
BEGIN

	if(@pWorkerNo is null or @pWorkerNo = '')
		return -1

	set nocount on

	declare @GetNums int
	declare @DataID varchar(250)
	declare @strSQL varchar(1000)
	declare @RoleID int
	select @RoleID = EmpID from tEmployee where EmpID = @pWorkerNo

	if @@ERROR != 0 goto Err_Proc

	if(@RoleID is null) set @RoleID = 0				--防止该用户不存在而引发错误

	--看该中干是否有该模块的该操作的权限
	select 
		@GetNums = count(ObjID) 
	from 
		tRightList 
	where 
		ObjID = @pWorkerNo 
		and ObjType = 1 
		and ModelID = @pModelID
		and charindex(@pOperator,Operator) > 0

	if @@ERROR != 0 goto Err_Proc
	if(@GetNums > 0) goto OK	--有权限

	--看该中干隶属角色是否有该模块的该操作的权限
	set @DataID=''
	select @DataID=@DataID+','+convert(varchar(5),DataID) from tGroupEmployee where EmpID= @pWorkerNo
	set @DataID=right(@DataID,len(@DataID)-1)
	set @strSQL='select ObjID from tRightList where ObjID in ('+@DataID+') and ObjType = 2 and ModelID = '+Convert(varchar(12),@pModelID)
	set @strSQL=@strSQL+' and charindex('''+@pOperator+''',Operator) > 0'
	 --=convert(varchar(2),@RoleID) 
	exec(@strSQL)
	if(@@ROWCOUNT > 0) goto OK
	else  goto Err_Proc

--select @strSQL
	--if @@ERROR != 0 goto Err_Proc
	--if(@@ROWCOUNT > 0) goto OK	--有权限

	set nocount off
	return -1
Err_Proc:
	set nocount off
	return -2
OK:
	set nocount off
	return 0

END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*
功能：
	数据库业务数据清空。

参数：@PtillDate 此日期之前的所有业务数据都做清空处理

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_CleanBizData]
@PgetDate varchar(10)
 AS
BEGIN

if(@PgetDate<>'')
begin

declare @PtillDate DateTime
set @PtillDate=convert(DateTime,@PgetDate)


	SET NOCOUNT ON
	BEGIN TRAN

	--清空采购数据
	delete from  tBuyPay where PayTime<=@PtillDate and Status=1	--删除采购财务表中已经做过收退款审核的数据
	if @@ERROR != 0 goto Err_Proc

	delete from  tDetailOfBuy where( BuyDate<=@PtillDate and (((BackBillID is null) and (CancelNums=0) and (not (PutInBillID is null))) or ((not(PutInBillID is null)) and (CancelNums<>0) and (not (BackBillID is null)) ))) and (not BillOfBuyID in (select BillOfBuyID from tBuyPay ))	--删除采购详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfBuy where (not BillOfBuyID in (select isnull(BillOfBuyID,0) from  tDetailOfBuy))	--删除采购主表数据
	if @@ERROR != 0 goto Err_Proc
	--清空采购数据完毕


	--清空销售数据
	delete from tSellPay where PayTime<=@PtillDate and Status=1 	--删除销售财务表中收付款已经审核生效的数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfSell  where  (SellDate<=@PtillDate and (((BackBillID is null) and (CancelNums=0) and (not (TakeOutBillID is null))) or ((not(TakeOutBillID is null)) and (CancelNums<>0) and (not (BackBillID is null)) )))   and  (not BillOfSellID in (select BillOfSellID from  tSellPay  ))	 --删除销售详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfSell  where( not  BillOfSellID in (select isnull(BillOfSellID,0)  from tDetailOfSell)) --删除销售主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfOrder   where ( not OrderID in (select isnull(OrderID,0)  from tBillOfSell  ))  and (OrderID in (select isnull(OrderID,0) from tOrder where Processed=1 )) --删除销售订单详细表数据
	if @@ERROR != 0 goto Err_Proc 

	delete from tOrder  where (not  OrderID in (select isnull(OrderID,0)  from tDetailOfOrder))   --删除销售订单主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfSellBack where CancelDate<=@PtillDate and BackBillID<>0  --客户退货明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tSellBack  where ( not SellBackID in (select  SellBackID from tDetailOfSellBack))   --客户退货主表
	if @@ERROR != 0 goto Err_Proc


	--清空销售数据完毕

	
	--清空库存数据
	delete from tDetailOfTakeoutSource where DetailIDOfPutin in (select isnull(DetailID,0) from tDetailOfPutin join tBillOfPutin on tDetailOfPutin.BillOfPutinID=tBillOfPutin.BillOfPutinID where tBillOfPutin.PutInTime<=@PtillDate  and tBillOfPutin.Status=1 )	--出库单明细来源（入库单明细）表
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfCheckCount where CheckTableID in (select isnull(CheckTableID,0) from tCheckTable where CheckDate<=@PtillDate and status=1 ) --盘点统计明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tTakeoutForm where PutinDetailID in (select isnull(DetailID,0) from tDetailOfPutin join tBillOfPutin on tDetailOfPutin.BillOfPutinID=tBillOfPutin.BillOfPutinID where tBillOfPutin.PutInTime<=@PtillDate  and tBillOfPutin.Status=1 ) --清除入库单货物组成记录
	if @@ERROR != 0 goto Err_Proc

	delete from tTakeoutForm where TakeoutDetailID in (select isnull(DetailID,0) from tDetailOfTakeout join tBillOfTakeout on tDetailOfTakeout.BillOfTakeoutID=tBillOfTakeout.BillOfTakeoutID where tBillOfTakeout.TakeOutTime<=@PtillDate  and tBillOfTakeout.Status=1 ) --清除出库单货物组成记录
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfPutin where BillOfPutinID in (select isnull(BillOfPutinID,0) from tBillOfPutin where PutinTime<=@PtillDate and status=1 ) --删除入库获取详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfPutin where PutinTime<=@PtillDate and status=1 --删除入库货物主表数据
	if @@ERROR != 0 goto Err_Proc
 
 	  delete from tDetailOfTakeout  where (not  DetailID in (select DetailID  from tDetailOfTakeoutSource  ) )  --删除出库货物详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfTakeout where (not BillOfTakeoutID in (select BillOfTakeoutID  from tDetailOfTakeout  )) --删除出库货物主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfCheckTable where CheckTableID in (select isnull(CheckTableID,0) from tCheckTable where CheckDate<=@PtillDate and status=1) --删除库存盘点详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tCheckTable where CheckDate<=@PtillDate and status=1 --删除库存盘点主表数据
	if @@ERROR != 0 goto Err_Proc
	
	delete from tDetailOfExchange where BillOfExchangeID in (select  isnull(BillOfExchangeID,0) from tBillOfExchange where  ExchangeDate<=@PtillDate and status=1  )
	if @@ERROR != 0 goto Err_Proc
	
	delete from tBillOfExchange where  ExchangeDate<=@PtillDate and status=1 --删除调拨单
	if @@ERROR != 0 goto Err_Proc

	--清空库存数据完毕




	delete from TCalCheckinReportData where CheckInDate<=@PtillDate  --手工统计上报明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tCheckinReport where CheckinDate<=@PtillDate  --手工统计上报主表
	if @@ERROR != 0 goto Err_Proc

	delete from tCustomerRelation where CheckinReportID in (select isnull(CheckinReportID,0) from tCheckinReport where CheckinDate<=@PtillDate ) --手工上报客户关系表 
	if @@ERROR != 0 goto Err_Proc


	goto OK_Proc

OK_Proc:
	print 'SUCCESS !'

	commit tran
	set nocount off
	return 0
Err_Proc:
	print 'FAILURE !'

	rollback tran
	set nocount off
	return -1
END

end

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
GO


/*
功能：
	数据库数据清空。

参数：@pCleanBaseData=0 保留基础配置数据； @pCleanBaseData=1 清空基础配置数据

返回：
	0	成功
	1	失败
*/
CREATE   PROCEDURE [storage].[sp_CleanData]
	@pCleanBaseData int =0
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN


	--清空采购数据
	delete from  tBuyPay	--删除采购财务表数据
	if @@ERROR != 0 goto Err_Proc

	delete from  tDetailOfBuy	--删除采购详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfBuy	--删除采购主表数据
	if @@ERROR != 0 goto Err_Proc
	--清空采购数据完毕


	--清空销售数据
	delete from tSellPay	--删除销售数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfSell --删除销售详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfSell --删除销售主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfOrder --删除销售订单详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tOrder --删除销售订单主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfSellReport --财务表
	if @@ERROR != 0 goto Err_Proc

	delete from tSellReport --财务表
	if @@ERROR != 0 goto Err_Proc

	delete from tSellReportFirst
	if @@ERROR != 0 goto Err_Proc
	--清空销售数据完毕
		

	--清空库存数据
	delete from tDetailOfExchange --仓库调拨
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfExchange  --仓库调拨
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfTakeoutSource	--出库单明细来源（入库单明细）表
	if @@ERROR != 0 goto Err_Proc

	delete from tProductStoreNums		--产品库存表
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfCheckCount --盘点统计明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tCheckTableFirst --盘点期初表	
	if @@ERROR != 0 goto Err_Proc

	delete from tTakeoutForm  --出库单货物组成记录
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfPutin --删除入库获取详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfPutin --删除入库货物主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfTakeout --删除出库货物详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tBillOfTakeout --删除出库货物主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfCheckTable --删除库存盘点详细表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tCheckTable --删除库存盘点主表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tStoreHouse --删除库房
	if @@ERROR != 0 goto Err_Proc
	--清空库存数据完毕


	--清空客户数据
	delete from tCustomerProductPrice	--客户产品价格
	if @@ERROR != 0 goto Err_Proc

	delete from tRakeOffProduct		--
	if @@ERROR != 0 goto Err_Proc

	delete from tCustomerPay		--
	if @@ERROR != 0 goto Err_Proc

	delete from tRakeOffGoods --返点货物清单
	if @@ERROR != 0 goto Err_Proc

	delete from tCommYearTaskMoney --删除通用某年任务额表数据
	if @@ERROR != 0 goto Err_Proc

	delete from tCommRakeOff --通用销售返点设置
	if @@ERROR != 0 goto Err_Proc

	delete from tYearTaskMoney --删除某年任务额
	if @@ERROR != 0 goto Err_Proc

	delete from tRakeOff --客户销售返点设置
	if @@ERROR != 0 goto Err_Proc

	delete from tSMSCustomer --短信发送客户列表
	if @@ERROR != 0 goto Err_Proc

	delete from tSms --短信发送记录表
	if @@ERROR != 0 goto Err_Proc

	delete from tKeepFee --维护费用
	if @@ERROR != 0 goto Err_Proc

	delete from tPayRakeOff --客户返点表
	if @@ERROR != 0 goto Err_Proc

	delete from tContract --合同
	if @@ERROR != 0 goto Err_Proc

	delete from tAfterService --售后服务
	if @@ERROR != 0 goto Err_Proc

	delete from tCustomer --客户信息表
	if @@ERROR != 0 goto Err_Proc

	delete from tDetailOfSellBack --客户退货明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tSellBack --客户退货主表
	if @@ERROR != 0 goto Err_Proc

	delete from TCalCheckinReportData --手工统计上报明细表
	if @@ERROR != 0 goto Err_Proc

	delete from tCheckinReport  --手工统计上报主表
	if @@ERROR != 0 goto Err_Proc

	delete from tCustomerRelation --手工上报客户关系表 
	if @@ERROR != 0 goto Err_Proc
	--清空客户数据完毕


	--清空产品数据
	delete from tSubProcStatusPrice 
	if @@ERROR != 0 goto Err_Proc

	delete from tProductStatusPrice
	if @@ERROR != 0 goto Err_Proc

	delete from tProductPrice --产品价格
	if @@ERROR != 0 goto Err_Proc

	delete from tUnitConversion --计量单位换算
	if @@ERROR != 0 goto Err_Proc

	delete from tGoods --货物
	if @@ERROR != 0 goto Err_Proc
	--清空产品数据完毕


	--清空计量单位
	delete from tUnit

	if @@ERROR != 0 goto Err_Proc
	--清空计量单位数据完毕


	--清空质检数据
	delete from tProductQCRecDetail --质检报表明细
	if @@ERROR != 0 goto Err_Proc

	delete from tProductQCRecord --质检报表
	if @@ERROR != 0 goto Err_Proc

	delete from tQuantityCheckstandard --质检标准
	if @@ERROR != 0 goto Err_Proc
	--清空质检数据完毕

	--清空生产数据
	delete from tBuyApplyDetail        --采购申请单
	if @@ERROR != 0 goto Err_Proc
	delete from tBuyApply
	if @@ERROR != 0 goto Err_Proc

	delete from tProductMainPlanDetail --生产经营计划单
	if @@ERROR != 0 goto Err_Proc
	delete from tProductMainPlan
	if @@ERROR != 0 goto Err_Proc

	delete from tProductPlanDetail --产经营计
	if @@ERROR != 0 goto Err_Proc
	delete from tProductPlan
	if @@ERROR != 0 goto Err_Proc

	delete from tSendWorkerDetail --派工单
	if @@ERROR != 0 goto Err_Proc
	delete from tSendWorker
	if @@ERROR != 0 goto Err_Proc

	delete from tProductInstallDetail --产品配置
	if @@ERROR != 0 goto Err_Proc
	delete from tProductInstall
	if @@ERROR != 0 goto Err_Proc

	delete from tGetMaterialDetail --生产领料
	if @@ERROR != 0 goto Err_Proc
	delete from tGetMaterial
	if @@ERROR != 0 goto Err_Proc

	delete from tCalcUnit --计件定额
	if @@ERROR != 0 goto Err_Proc

	delete from tCalcDetail --计件单
	if @@ERROR != 0 goto Err_Proc
	delete from tCalcSheetDetail
	if @@ERROR != 0 goto Err_Proc
	delete from tCalcSheet
	if @@ERROR != 0 goto Err_Proc

	delete from tClassDoc --车间档案
	if @@ERROR != 0 goto Err_Proc

	delete from tWorkpreface --工序定义
	if @@ERROR != 0 goto Err_Proc

	delete from tEquipmentsDoc  --设备档案
	if @@ERROR != 0 goto Err_Proc

	delete from tCrafRouteDetail --工艺路线
	if @@ERROR != 0 goto Err_Proc
	delete from tCrafRoute
	if @@ERROR != 0 goto Err_Proc

	delete from tCostOfProduct --生产成本核算
	if @@ERROR != 0 goto Err_Proc

	delete from tClassDocLog   --车间记事
	if @@ERROR != 0 goto Err_Proc
	--清空生产数据完毕

	--清空行政中心数据
	delete from tDocType --清空公文头表
	if @@ERROR != 0 goto Err_Proc 

	delete from tDocRS --清空公文接收信息表
	if @@ERROR != 0 goto Err_Proc 
	
	delete from tReInfo --清空反馈信息表
	if @@ERROR != 0 goto Err_Proc 

	delete from tDocMain --清空公文管理表
	if @@ERROR != 0 goto Err_Proc 

	delete from tGroupEmployee --清空员工所在权限组
	if @@ERROR != 0 goto Err_Proc 

	delete from tMenuOfPerson --清空个人快捷菜单项
	if @@ERROR != 0 goto Err_Proc 

	delete from tSheetCode --清空公司编码项
	if @@ERROR != 0 goto Err_Proc 

	delete from tModel --清空模块定义表
	if @@ERROR != 0 goto Err_Proc 
	--清空行政中心数据完毕

	--清空基础数据
	if(@pCleanBaseData=1)
	begin
		delete from tCustomerPay --财务表
		if @@ERROR != 0 goto Err_Proc

		delete from tEmployee --清空员工
		if @@ERROR != 0 goto Err_Proc

		delete from tDepartment --清空部门
		if @@ERROR != 0 goto Err_Proc

		delete from tCompany --清空公司
		if @@ERROR != 0 goto Err_Proc

		delete from tRightList --删除权限配置表
		if @@ERROR != 0 goto Err_Proc

		delete from tBaseData --清空一级基础数据表
		if @@ERROR != 0 goto Err_Proc

		delete from tBaseDataTree --清空多级基础数据表
		if @@ERROR != 0 goto Err_Proc

		delete from tCompanyEmployee --清空公司员工数据表
		if @@ERROR != 0 goto Err_Proc
	end

	delete from tArea --清空区域表
	if @@ERROR != 0 goto Err_Proc
	--清空基础数据完毕


	goto OK_Proc

OK_Proc:
	print 'SUCCESS !'

	commit tran
	set nocount off
	return 0
Err_Proc:
	print 'FAILURE !'

	rollback tran
	set nocount off
	return -1
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
	where E.GoodsType=G.GoodsType and A.pNo=@pNo

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
	where E.GoodsType=D.GoodsType and A.pNo=@pNo
	select @Eq = sum(ToFee*Number*Nums) from #EqFee

	--从生产请求单中统计
	select @Sale = sum(TotalMoney) from tProductPlan where pNo=@pNo

	set @AllCost=@Material+@Calc+@Eq
	set @Cost = @Sale -@AllCost

	--输出结果集
	select @pNo AS pNo,IsNull(@Material1,0) AS Material1,IsNull(@Material2,0) AS Material2,IsNull(@Material3,0) AS Material3,IsNull(@Material,0) AS Material,IsNull(@Calc,0) AS Calc,IsNull(@Eq,0) AS Eq,IsNull(@AllCost,0) AS AllCost,@Sale AS Sale,IsNull(@Cost,0) AS Cost


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
	where E.GoodsType=G.GoodsType and A.pNo=@pNo
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
	declare @SheetNoM   varchar(20)
	declare @SheetNoB   varchar(20)

	set @SheetNoM=@SheetNo+'M'
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
	where E.GoodsType=G.GoodsType and A.sheetid=@SheetID

	if((select Count(*) from  #GetMaterial)>0)
	begin
		insert into tGetMaterial(BillNO,MakeBillMan,MakeBillDate,pNo,TakeoutType,SendWorkID)
		values(@SheetNoM,@MakeBillMan,getdate(),@pNo,0,@SheetID)
		set @ID = @@IDENTITY

		insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,Model,Spec,Price,pNo,OutNums,UnitName,CurStoreNums)
		select @ID,ProductID,SourceNo,Model,Spec,Price,@pNo,Number,Unit,CurStoreNums from #GetMaterial where GoodsType<2

		insert into tGetMaterial(BillNO,MakeBillMan,MakeBillDate,pNo,TakeoutType,SendWorkID)
		values(@SheetNoB,@MakeBillMan,getdate(),@pNo,0,@SheetID)
		set @ID = @@IDENTITY

		insert into tGetMaterialDetail(BillOfTakeoutID,GoodsID,GoodsCode,Model,Spec,Price,pNo,OutNums,UnitName,CurStoreNums)
		select @ID,ProductID,SourceNo,Model,Spec,Price,@pNo,Number,Unit,CurStoreNums from #GetMaterial where GoodsType=3
	end


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
	EXEC('insert into tSendWorkerDetail(SheetID,ProductID,ProductNo,ProductName,Model,Spec,Unit,Price,Number,PNO,Moneys)
		select '+@ID+',ProID,ProductNo,ProductName,Model,Spec,Unit,Price,Number,PNO,Moneys from tProductPlanDetail
		where DetailID in ('+@DetailID+')')


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	重销售单处插入客户的应付额
参数：
	@CustID	客户ID
	@AllMoney	应付额
返回：
	0成功，
	-1失败
*/
CREATE PROCEDURE [storage].[sp_CustomerAllMoney] 
(@CustID numeric,
@AllMoney numeric(12,2) )
as
BEGIN 
	SET NOCOUNT ON
	
	exec ('SELECT * FROM tCustomerPay WHERE CustomerID='+@CustID+' AND Status=0')


	if (@@rowcount>0)
	begin
		exec( 'UPDATE tCustomerPay SET CountAllMoney=CountAllMoney+'+@AllMoney+' WHERE CustomerID='+@CustID+' AND Status=0')
		if @@ERROR!=0 goto Err_Proc
	end
	else
	begin
		exec('INSERT INTO tCustomerPay(CustomerID,CountAllMoney) VALUES('+@CustID+','+@AllMoney+') ')
		if @@ERROR!=0 goto Err_Proc
	end

	set nocount off
	return 0
        Err_Proc:

	set nocount off
	return -1
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	删除指定的多笔出库调拨单。

参数：
	@pIDS	varchar(8000)	多笔调拨单ID组成的字串（逗号分隔）

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_DelMutiBillOfExchange]
(
	@pIDS varchar(8000)	--多笔调拨单ID组成的字串（逗号分隔）
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(8000)
	set @strSQL = 'delete from tDetailOfExchange where BillOfExchangeID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	set @strSQL = 'delete from tBillOfExchange where BillOfExchangeID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc
OK_Proc:
	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	删除指定的多笔入库单。

参数：
	@pIDS	varchar(8000)	多笔入库单ID组成的字串（逗号分隔）

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_DelMutiBillOfPutin]
(
	@pIDS varchar(8000)	--多笔入库单ID组成的字串（逗号分隔）
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(8000)
	set @strSQL = 'delete from tDetailOfPutin where BillOfPutinID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	set @strSQL = 'delete from tBillOfPutin where BillOfPutinID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc
OK_Proc:
	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	删除指定的多笔出库单。

参数：
	@pIDS	varchar(8000)	多笔出库单ID组成的字串（逗号分隔）

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_DelMutiBillOfTakeout]
(
	@pIDS varchar(8000)	--多笔出库单ID组成的字串（逗号分隔）
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(8000)
	set @strSQL = 'delete from tDetailOfTakeout where BillOfTakeoutID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	set @strSQL = 'delete from tBillOfTakeout where BillOfTakeoutID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc
OK_Proc:
	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	删除指定的多笔盘点表。

参数：
	@pIDS	varchar(8000)	多笔出盘点表ID组成的字串（逗号分隔）

返回：
	0	成功
	1	失败
*/
CREATE  PROCEDURE [storage].[sp_DelMutiCheckTable]
(
	@pIDS varchar(8000)	--多笔出库单ID组成的字串（逗号分隔）
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN

	declare @strSQL varchar(8000)
	set @strSQL = 'delete from tDetailOfCheckTable where CheckTableID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc

	set @strSQL = 'delete from tCheckTable where CheckTableID in (' + @pIDS + ') and Status=0'
	exec(@strSQL)
	if @@ERROR != 0 goto Err_Proc
OK_Proc:
	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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

		SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
		insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
		values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,null,@TablePerson,getdate(),0,0,0,0,0)
		set @ID = @@IDENTITY

		insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
		select @ID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,OutNums,Number,CurStoreNums,Price,0,0,(select UnitID from tGoods where GoodsID = A.GoodsID)as UnitID,(select Color from tGoods where GoodsID = A.GoodsID)as Color,GoodsType from #BuyApplyDetail A
	end


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：
	获取指定模块的对象（员工、角色）的权限配置数据列表
参数：
	@pModelID	int		模块ID；
	@pObjType	varchar(2)	对象类别（W-中干  R-角色）
返回：
	0	成功；
	-1	异常错误；
*/
CREATE PROCEDURE [Storage].[sp_GetModelRightList]
(
	@pModelID	int,
	@pObjType	varchar(2)
)
 AS
BEGIN

	set nocount on

	create table #tmpTable
	(
		objChk		varchar(100),	--是否选中的checkbox的html
		objID		varchar(20),	--对象ID
		ObjName		varchar(500),	--对象名称
		Operator	varchar(2500),	--操作
		Range		varchar(2500),	--范围
		PDeptName	varchar(500),	--部门名称（角色用空格表示）
		PCompName	varchar(500)	--公司名称（角色用空格表示）
	)

	begin tran

	--把所有的对象及其权限配置数据写入临时表
if(@pObjType = 'W')
begin
	insert into #tmpTable
	select
		'<input type="checkbox" id="chkID" onclick="CS(' + Convert(varchar(10),w.EmpID) + ')" name="chkID" value="' + Convert(varchar(10),w.EmpID) + '" checked>',
		w.EmpID,
		w.EmpName,
		Storage.fnGetOperatorDispStr(r.ObjID,@pModelID,r.Operator,'W'),
		Storage.fnGetRangeDispStr(r.ObjID,@pModelID,r.Range,'W'),
		w.DeptID,
		w.CompID
	from
		tEmployee w
	left outer join
		tRightList r
	on
		r.ModelID = @pModelID
		and w.EmpID = r.ObjID
	--order by
	--	m.PModelName,m.ModelID

	if(@@ERROR <> 0) goto ErrProc

	--更新没有指定权限的模块为非选中状态
	update
		#tmpTable
	set
		objChk = '<input type="checkbox" name="chkID" id="chkID" onclick="CS(' + ObjID + ')" value="' + ObjID + '">',
		Operator = Storage.fnGetOperatorDispStr(objID,@pModelID,Operator,'W'),
		Range = Storage.fnGetRangeDispStr(ObjID,@pModelID,Range,'W')
	where
		Operator is null
	if(@@ERROR <> 0) goto ErrProc

	select
		t.objChk,
		t.objID,
		t.ObjName,
		t.Operator,
		t.Range,
		d.DeptName as PDeptName,
		c.CompName as PCompName
	from
		#tmpTable t,
		tDepartment d,
		tCompany c
	where
		t.PDeptName = d.DeptID and t.PCompName=c.CompID
	order by
		d.DeptName
end
else
begin
	insert into #tmpTable
	select
		'<input type="checkbox" name="chkID" id="chkID" onclick="CS(' +  w.RoleID + ')" value="' + w.RoleID + '" checked>',
		w.RoleID,
		w.RoleName,
		Storage.fnGetOperatorDispStr(r.ObjID,@pModelID,r.Operator,'W'),
		Storage.fnGetRangeDispStr(r.ObjID,@pModelID,r.Range,'W'),
		'',
		''
	from
		(select  convert(varchar(10),DataID) as RoleID,DataValue as RoleName from tBaseData where DataType=15) as w
	left outer join
		tRightList r
	on
		r.ModelID = @pModelID
		and w.RoleID = r.ObjID
	order by
		w.RoleID

	if(@@ERROR <> 0) goto ErrProc

	--更新没有指定权限的模块为非选中状态
	update
		#tmpTable
	set
		objChk = '<input type="checkbox" name="chkID" id="chkID" onclick="CS(' + Convert(varchar(10),objID) + ')" value="' + Convert(varchar(10),objID) + '">',
		Operator = Storage.fnGetOperatorDispStr(objID,@pModelID,Operator,'W'),
		Range = Storage.fnGetRangeDispStr(ObjID,@pModelID,Range,'W')
	where
		Operator is null

	if(@@ERROR <> 0) goto ErrProc

	select * from #tmpTable
end

	drop table #tmpTable
	commit tran
	set nocount off
	return 0

ErrProc:
	rollback tran
	drop table #tmpTable
	return -1
end
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*
功能：
	获取指定对象（员工、角色）的模块权限配置数据列表
参数：
	@pObjID	varchar(20)	对象ID；
	@pModelID	int		父模块编号；
返回：
	0	成功；
	-1	异常错误；
*/
CREATE PROCEDURE [Storage].[sp_GetObjRightList]
(
	@pObjID	varchar(20),
	@pModelID	int,		--0表示所有模块
	@pObjType	int
)
 AS
BEGIN
	

	set nocount on

	create table #tmpTable
	(
		objChk		varchar(1000),	--是否选中的checkbox的html
		ModelID		int,		--模块ID
		ModelName	varchar(50),	--模块名称
		Operator	nvarchar(4000),	--操作
		Range		varchar(2500),	--范围
		PModelName	varchar(50)	--父模块名称
	)

	begin tran

	--把所有的模块及其权限配置数据写入临时表
	insert into #tmpTable
	select
		'<input id="chkID" type="checkbox" name="chkID" onclick="CS(' + convert(varchar(10),m.ModelID) + ')" value="' + convert(varchar(10),m.ModelID) + '" checked>',
		m.ModelID,
		convert(varchar(10),m.ModelID) + '　' + m.ModelName as ModelName,
		Storage.fnGetOperatorDispStr(@pObjID,r.ModelID,r.Operator,'M'),
		Storage.fnGetRangeDispStr(@pObjID,r.ModelID,r.Range,'M'),
		m.PModelName
	from
		(select * from tModel where PModelID = @pModelID) m
	left outer join
		tRightList r
	on
		r.ObjID = @pObjID
		and ObjType = @pObjType
		and m.ModelID = r.ModelID
	order by
		m.PModelName,m.OrderNums

	if(@@ERROR <> 0) goto ErrProc


	--更新没有指定权限的模块为非选中状态
	update
		#tmpTable
	set
		objChk = '<input id="chkID" type="checkbox" name="chkID" onclick="CS(' + convert(varchar(10),ModelID) + ')" value="' + convert(varchar(10),ModelID) + '">',
		Operator = Storage.fnGetOperatorDispStr(@pObjID,ModelID,Operator,'M'),
		Range = Storage.fnGetRangeDispStr(@pObjID,ModelID,Range,'M')
	where
		Operator is null

	if(@@ERROR <> 0) goto ErrProc

	select * from #tmpTable
	if(@@ERROR <> 0) goto ErrProc

	drop table #tmpTable
	commit tran
	set nocount off
	return 0

ErrProc:
	rollback tran
	drop table #tmpTable
	return -1
end
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
GO


CREATE            PROCEDURE [storage].[sp_GetRecordFromPage] 
    @tblName      varchar(255),       -- 表名 
    @fldName      varchar(255),       -- 字段名 
    @colName      varchar(255)='',    -- 查询的列名
    @PageSize     int = 10,           -- 页尺寸 
    @PageIndex    int = 1,            -- 页码 
    @IsCount      bit = 0,            -- 返回记录总数, 非 0 值则返回 
    @OrderType    bit = 0,            -- 设置排序类型, 非 0 值则降序 
    @strWhere     varchar(1000) = ''  -- 查询条件 (注意: 不要加 where) 
AS 

declare  @strSQL   varchar(2000)     -- 主语句 
declare @strTmp   varchar(1000)     -- 临时变量 
declare @strOrder varchar(1000)       -- 排序类型 
declare @strcol varchar(1000)        --查询列名

if @OrderType != 0 
begin 
    set @strTmp = '<(select min' 
    set @strOrder = ' order by ' + @fldName +' desc' 
end 
else 
begin 
    set @strTmp = '>(select max' 
    set @strOrder = ' order by ' + @fldName +' asc' 
end 

if @colName!=''
begin 
set @strcol='select top ' + str(@PageSize) + ' '+@colName+' from '
end 
else
begin
set @strcol='select top ' + str(@PageSize) + ' * from '
end

set @strSQL = @strcol+ @tblName + ' where ' + @fldName + '' + @strTmp + '(' 
    + @fldName + ') from (select top ' + str((@PageIndex-1)*@PageSize) + ' ' 
    + @fldName + ' from ' + @tblName + '' + @strOrder + ') as tblTmp)' 
    + @strOrder 

if @strWhere != '' 
    set @strSQL = @strcol+ @tblName + ' where ' + @fldName + '' + @strTmp + '(' 
        + @fldName + ') from (select top ' + str((@PageIndex-1)*@PageSize) + ' ' 
        + @fldName + ' from ' + @tblName + ' where (' + @strWhere + ') ' 
        + @strOrder + ') as tblTmp) and (' + @strWhere + ') ' + @strOrder 

if @PageIndex = 1 
begin 
    set @strTmp = '' 
    if @strWhere != '' 
        set @strTmp = ' where (' + @strWhere + ')' 

    set @strSQL = @strcol+ @tblName + '' + @strTmp + ' ' + @strOrder 
end 

if @IsCount != 0 
    set @strSQL = 'select count(*) as Total from ' + @tblName + ' where (' + @strWhere + ')' 
exec (@strSQL)

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
GO


/*

功能：
	生产请求能力分析

参数：
	@SheetID  int                  --生产请求单ID

返回：

基本算法：
*/
CREATE   PROCEDURE [storage].[sp_MaterialCount]
	@SheetID  int                  --生产请求单ID
AS
	select D.ProductID,D.SourceNo,D.SourceName,D.Model,D.Spec,D.Unit,(B.Number * D.number * ISNULL(F.nums,1)) as Number,G.CurStoreNums,G.GoodsType  from tproductplan as A 
	inner join tproductplandetail as B on A.sheetid = B.sheetid
	inner join tproductinstall as C on B.proid = C.productid
	inner join tproductinstalldetail as D on C.insid=D.insid 
	inner join tgoods as G on G.GoodsID  = D.productid
	inner join tunit as E on B.unit = E.unitname
	left join tunitconversion F on F.unitid = E.unitid
	where A.sheetid=@SheetID 



GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

setuser N'Storage'
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
	where E.GoodsType = G.GoodsType and A.sheetid=@SheetID

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

		SELECT @SequenceNum= IsNull(max(SequenceNum),0)+1 FROM tBillOfBuy
	
		insert into tBillOfBuy(BillNo,SequenceNum,ApplyTime,BuyReason,ApplyPerson,DeptID,WriteMan,WriteTime,Status,AllMoney,FactAllMoney,CountAllMoney,GoodsType)
		values(@SheetNo,@SequenceNum,getdate(),'生产领料库存不足',@ApplyPerson,@DeptID,@TablePerson,getdate(),0,0,0,0,0)
		set @ID = @@IDENTITY

		insert into tDetailOfBuy(BillOfBuyID,GoodsID,GoodsCode,GoodsName,Model,Spec,UnitName,UseNumber,Nums,CurStoreNums,Price,FactMoney,SubMoney,UnitID,Color,ProcType)
		select @ID,ProductID,SourceNo,SourceName,Model,Spec,Unit,Number,BuyNumber,CurStoreNums,Price,0,0,UnitID,Color,GoodsType from #ApplyDetail
	end


GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	付款审核

参数：
	@pPayID	int	付款表ID
	@pCustPayID		int		客户付款记录表ID
	@pStatus	int		状态
	@pPayMoney 	numeric(12,2)	付款额
	@pCheckMan	varchar(20)		审核人

返回：
	0	成功
	-1	失败
*/
CREATE PROCEDURE [Storage].[sp_PayCheck]
(
	@pPayID	int,	--付款表ID
	@pCustPayID	int,		--客户付款记录表ID
	@pStatus	int,		--状态(0收款，1付款，2返点额, 3调整项目,4维护费用,5托运费)
	@pPayMoney 	numeric(12,2),	--付款额
	@pCheckMan	varchar(20)		--审核人
) AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRAN
	
	declare @ToDayDate varchar(50)--当前日期
	declare @strSQL varchar(1000)
	
	set @ToDayDate = Convert(varchar(10),DatePart(year,getdate()))+'-'
				+Convert(varchar(10),DatePart(month,getdate()))+'-'
				+Convert(varchar(10),DatePart(day,getdate()))
	
	set @strSQL = 'update tSellPay set Status=1,CheckMan='''+@pCheckMan+''',CheckTime='''+@ToDayDate+''''
	set @strSQL = @strSQL+',CPayID='+convert(varchar(50),@pCustPayID)

	set @strSQL = @strSQL+' where PayID='+convert(varchar(50),@pPayID)
--print @strSQL
--return 
	exec(@strSQL)--刷新付款表的状态
	if @@ERROR!=0 goto Err_Proc
	
	set @strSQL ='update tCustomerPay set PayMoney=PayMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=0) set @strSQL =@strSQL+',AcceptMoney=AcceptMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=1) set @strSQL ='update tCustomerPay set CountAllMoney=CountAllMoney-'+convert(varchar(50),@pPayMoney)+',BackMoney=BackMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=2) set @strSQL =@strSQL+',ReturnMoney=ReturnMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=3) set @strSQL ='update tCustomerPay set CountAllMoney=CountAllMoney+'+convert(varchar(50),@pPayMoney)+',TuneMoney=TuneMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=4) set @strSQL =@strSQL+',KeepMoney=KeepMoney+'+convert(varchar(50),@pPayMoney)
	if (@pStatus=5) set @strSQL =@strSQL+',CheckMoney=CheckMoney+'+convert(varchar(50),@pPayMoney)
	set @strSQL = @strSQL+' where PayID='+convert(varchar(50),@pCustPayID)
--print @strSQL
--return
	exec(@strSQL)--刷新客户付款表
	if @@ERROR!=0 goto Err_Proc

	set @strSQL='select PayID from tCustomerPay where CountAllMoney=PayMoney and PayID='+convert(varchar(50),@pCustPayID)
	exec(@strSQL)--查询该客户的该条付款记录是否付清
	if (@@ROWCOUNT>0) 
	begin 
		set @strSQL='update tCustomerPay set Status=1,SellAllDate='''+@ToDayDate+''' where PayID='+convert(varchar(50),@pCustPayID)
		exec(@strSQL)
		if @@ERROR!=0 goto Err_Proc
	end

	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	应收应付列表

参数：
	@pEmpID		int		业务员ID
	@pAreaID		int		地域ID
	@pStartDate	varchar(20)		开始日期
	@pEndDate	varchar(20)		结束日期
	@pMakeMan	varchar(50)		制单人

返回：
	-1表失败
	-2表该时间段已统计过
*/
CREATE PROCEDURE [Storage].[sp_PayList]
(
	@pEmpID		int=0,		--业务员ID
	@pAreaID		int=0,		--地域ID
	@pStartDate	varchar(20),		--开始日期
	@pEndDate	varchar(20),		--结束日期
	@pMakeMan	varchar(50)		--制单人
) AS
BEGIN
	SET NOCOUNT ON
	--BEGIN TRAN
	--BEGIN TRANSACTION
	declare @IDStr 		varchar(250)
	declare @String	varchar(500)
	set @IDStr=''
	select @IDStr=@IDStr+Convert(varchar(10),ReportID)+',' from tSellReport where EndDate>=@pStartDate
	if len(@IDStr)>1
	begin
		set @IDStr=left(@IDStr,len(@IDStr)-1)
		set @String='select ListID from tDetailOfSellReport Where ReportID in('+@IDStr+')'
		if @pEmpID>0 set @String=@String+' and EmpID='+Convert(varchar(10),@pEmpID)
		if @pAreaID>0 set @String=@String+' and AreaID='+Convert(varchar(10),@pAreaID)
		exec(@String)
		if @@ROWCOUNT>0 goto Time_Proc
	end
	--变量区-----------------------
	declare @SqlStr	varchar(250)
	declare @SStr		varchar(2500)
	declare @ReportID	int
	declare @CustID	varchar(2500)
	create table #tmpSellPay(    	--存储某时间段的已审核的所有付款明细
		CustomerID	numeric	not null,		--客户ID
		PayMoney	numeric(20,2),	--钱
		Type		int not null
				)
	create table #tmpStartSendPay(    	--存储某时间段的已审核的发货额
		CustomerID	numeric	not null,		--客户ID
		PayMoney	numeric(20,2)	--钱
				)
	create table #tmpCustPay(    	--存储所有客户的付款的总额
		CustID		int identity,
		CustomerID	numeric	not null,		--客户ID
		EmpID		numeric not null,		--业务员
		AreaID		numeric not null,		--地域ID
		FullName	varchar(200),	--客户名称
		StartMoney	numeric(20,2),	--期初余额
		SendMoney	numeric(20,2),	--发货额
		BackMoney	numeric(20,2),	--退货额
		TuneMoney	numeric(20,2),	--调整项目额
		ReturnMoney	numeric(20,2),	--扣点额（返点 ）
		KeepMoney	numeric(20,2),	--维护费用额
		AcceptMoney	numeric(20,2),	--回款额
		CheckMoney	numeric(20,2),	--托运额
		EndMoney	numeric(20,2)	--期末余额
				)
	create table #tmpEmpPay(    	--存储所有业务员的付款的总额
		ID		int identity,
		EmpID		numeric not null,		--业务员
		AreaID		numeric not null,		--地域
		StartMoney	numeric(20,2),	--期初余额
		SendMoney	numeric(20,2),	--发货额
		BackMoney	numeric(20,2),	--退货额
		TuneMoney	numeric(20,2),	--调整项目额
		ReturnMoney	numeric(20,2),	--扣点额（返点 ）
		KeepMoney	numeric(20,2),	--维护费用额
		AcceptMoney	numeric(20,2),	--回款额
		CheckMoney	numeric(20,2),	--托运额
		EndMoney	numeric(20,2)	--期末余额
				)
	create table #tmpAreaPay(    	--存储所有地区的付款的总额
		ID		int identity,
		AreaID		numeric not null,		--地域ID
		StartMoney	numeric(20,2),	--期初余额
		SendMoney	numeric(20,2),	--发货额
		BackMoney	numeric(20,2),	--退货额
		TuneMoney	numeric(20,2),	--调整项目额
		ReturnMoney	numeric(20,2),	--扣点额（返点 ）
		KeepMoney	numeric(20,2),	--维护费用额
		AcceptMoney	numeric(20,2),	--回款额
		CheckMoney	numeric(20,2),	--托运额
		EndMoney	numeric(20,2)	--期末余额
				)
	create table #tmpListPay(    	--总列表
		CustID		int identity,
		CustomerID	numeric,		--客户ID
		EmpID		numeric,		--业务员
		AreaID		numeric,		--地域
		Num		varchar(100),	--排序标号
		FullName	varchar(200),	--客户名称
		StartMoney	numeric(20,2),	--期初余额
		SendMoney	numeric(20,2),	--发货额
		BackMoney	numeric(20,2),	--退货额
		TuneMoney	numeric(20,2),	--调整项目额
		ReturnMoney	numeric(20,2),	--扣点额（返点 ）
		KeepMoney	numeric(20,2),	--维护费用额
		AcceptMoney	numeric(20,2),	--回款额
		CheckMoney	numeric(20,2),	--托运额
		EndMoney	numeric(20,2)	--期末余额
				)
	create table #tmpStartPay(    	--存储期初余额
		CustomerID	numeric	not null,		--客户ID
		StartMoney	numeric(20,2)	--期初余额
				)
	create table #tmpSendPay(    	--存储发货额
		CustomerID	numeric	not null,		--客户ID
		SendMoney	numeric(20,2)	--发货额
				)
	create table #tmpBackPay(    	--存储退货额
		CustomerID	numeric	not null,		--客户ID
		BackMoney	numeric(20,2)	--退货额
				)
	create table #tmpTunePay(    	--存储调整项目额
		CustomerID	numeric	not null,		--客户ID
		TuneMoney	numeric(20,2)	--调整项目额
				)
	create table #tmpReturnPay(    	--存储扣点额（返点)
		CustomerID	numeric	not null,		--客户ID
		ReturnMoney	numeric(20,2)	--扣点额（返点)
				)
	create table #tmpKeepPay(    	--存储维护费用额
		CustomerID	numeric	not null,		--客户ID
		KeepMoney	numeric(20,2)	--维护费用额
				)
	create table #tmpAcceptPay(    	--存储回款额
		CustomerID	numeric	not null,		--客户ID
		AcceptMoney	numeric(20,2)	--回款额
				)
	create table #tmpCheckPay(    	--存储托运额
		CustomerID	numeric	not null,		--客户ID
		CheckMoney	numeric(20,2)	--托运额
				)
	--逻辑区-----------------------
	set @SqlStr='insert into #tmpSellPay select CustomerID,PayMoney,Type from tSellPay where Status=1 and 
	CheckTime between '''+convert(varchar(20),@pStartDate)+''' and '''+convert(varchar(20),@pEndDate)+''''
	exec(@SqlStr)	--存储某时间段的已审核的所有付款明细
	select * from #tmpSellPay
	if @@ROWCOUNT<1
	begin
		set @ReportID=0
		goto Suc_Proc
	end
	set @SqlStr='insert into #tmpStartSendPay select CustomerID,FactMoney from vwSell where SellDate
			 between '''+convert(varchar(20),@pStartDate)+''' and '''+convert(varchar(20),@pEndDate)+''''
	exec(@SqlStr)	--存储某时间段的已审核的发货额
------------------------------------------------------------------
	set @SStr='insert into #tmpStartPay select C.CustomerID,SR.FirstMoney from tCustomer as C left join tSellReportFirst as SR on C.CustomerID=SR.CustomerID'
	exec(@SStr)--期初余额
	set @SStr='insert into #tmpSendPay select C.CustomerID,sum(S.PayMoney) from tCustomer as C left join #tmpStartSendPay as S
			 on C.CustomerID=S.CustomerID group by C.CustomerID order by C.CustomerID'
	exec(@SStr)--发货额
	set @SStr='insert into #tmpBackPay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=1 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--退货额
	set @SStr='insert into #tmpTunePay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=3 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--调整项目额
	set @SStr='insert into #tmpReturnPay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=2 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--扣点额（返点)
	set @SStr='insert into #tmpKeepPay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=4 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--维护费用额
	set @SStr='insert into #tmpAcceptPay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=0 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--回款额
	set @SStr='insert into #tmpCheckPay select CustomerID,SUM(PayMoney) from #tmpSellPay WHERE Type=5 GROUP BY CustomerID order by CustomerID'
	exec(@SStr)--托运额
------------------------------------------------------
	set @SStr='insert into #tmpCustPay(CustomerID,EmpID,AreaID,FullName,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'

	set @SStr=@SStr+' select C.CustomerID,C.EmpID,C.AreaID,C.FullName,isnull(SSP.StartMoney,0),isnull(SP.SendMoney,0),isnull(BP.BackMoney,0),
	isnull(TP.TuneMoney,0),isnull(RP.ReturnMoney,0),isnull(KP.KeepMoney,0),isnull(AP.AcceptMoney,0),
	isnull(CP.CheckMoney,0),
	(isnull(SSP.StartMoney,0)+isnull(SP.SendMoney,0)-isnull(BP.BackMoney,0)+isnull(TP.TuneMoney,0)
	-isnull(RP.ReturnMoney,0)-isnull(KP.KeepMoney,0)
	-isnull(AP.AcceptMoney,0)-isnull(CP.CheckMoney,0))
	 from tCustomer as C '
	
	set @SStr=@SStr+'left join #tmpStartPay as SSP on C.CustomerID=SSP.CustomerID '
	set @SStr=@SStr+'left join #tmpSendPay as SP on C.CustomerID=SP.CustomerID '
	set @SStr=@SStr+'left join #tmpBackPay as BP on C.CustomerID=BP.CustomerID '
	set @SStr=@SStr+'left join #tmpTunePay as TP on C.CustomerID=TP.CustomerID '
	set @SStr=@SStr+'left join #tmpReturnPay as RP on C.CustomerID=RP.CustomerID '
	set @SStr=@SStr+'left join #tmpKeepPay as KP on C.CustomerID=KP.CustomerID '
	set @SStr=@SStr+'left join #tmpAcceptPay as AP on C.CustomerID=AP.CustomerID '
	set @SStr=@SStr+'left join #tmpCheckPay as CP on C.CustomerID=CP.CustomerID where 1=1'
	if(@pEmpID>0)
		set @SStr=@SStr+'and EmpID='+Convert(varchar(10),@pEmpID)
	if(@pAreaID>0)
	 	set @SStr=@SStr+' and AreaID='+Convert(varchar(10),@pAreaID)


	exec(@SStr)	--	客户分组表

	set @SStr='insert into #tmpEmpPay(EmpID,AreaID,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'
	set @SStr=@SStr+' select EmpID,AreaID,sum(StartMoney),sum(SendMoney),sum(BackMoney),sum(TuneMoney),
		sum(ReturnMoney),sum(KeepMoney),sum(AcceptMoney),sum(CheckMoney),sum(EndMoney) from
		 #tmpCustPay group by EmpID,AreaID'
	exec(@SStr)	--	小计

	set @SStr='insert into #tmpAreaPay(AreaID,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'
	set @SStr=@SStr+' select AreaID,sum(StartMoney),sum(SendMoney),sum(BackMoney),sum(TuneMoney),
		sum(ReturnMoney),sum(KeepMoney),sum(AcceptMoney),sum(CheckMoney),sum(EndMoney) from
		 #tmpCustPay group by AreaID'
	exec(@SStr)	--	合计

	set @SStr='insert into #tmpListPay(CustomerID,EmpID,AreaID,Num,FullName,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'
	set @SStr=@SStr+' select CustomerID,EmpID,AreaID,Convert(varchar(10),AreaID)+Convert(varchar(10),EmpID)+Convert(varchar(10),CustomerID),FullName,StartMoney,
		SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,AcceptMoney,CheckMoney,EndMoney
		 from #tmpCustPay'
	exec(@SStr)	--	客户列表

	set @CustID=''
	select @CustID=@CustID+Convert(varchar(10),CustomerID)+',' from #tmpCustPay
	set @ReportID=0
	--新插入一条销售统计报表
	if len(@CustID)>1 --如果查询到有记录就执行
	begin
		set @SqlStr='insert into tSellReport(Title,BeginDate,EndDate,MakeBillMan,MakeBillDate) values(''启尔达财务报表'','''+@pStartDate+''','''+@pEndDate+''','''+@pMakeMan+''',getdate())'
		exec(@SqlStr)
		if @@ERROR!=0 goto Err_Proc
-----获取销售统计报表的最大ID
		
		select @ReportID=Max(ReportID) from tSellReport
----删除相应的销售统计报表
		set @CustID=left(@CustID,len(@CustID)-1)
		--select @CustID
		set @SqlStr='delete from tSellReportFirst where CustomerID in ('+@CustID+')'
		exec(@SqlStr)
		if @@ERROR!=0 goto Err_Proc
	end
--插入销售统计起初表
	insert into tSellReportFirst(CustomerID,FirstMoney) select CustomerID,EndMoney from #tmpCustPay
	if @@ERROR!=0 goto Err_Proc

	update tSellReportFirst set ReportID=@ReportID where ReportID=0
	if @@ERROR!=0 goto Err_Proc
	--

	set @SStr='insert into #tmpListPay(EmpID,AreaID,Num,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'
	set @SStr=@SStr+' select EmpID,AreaID,Convert(varchar(10),AreaID)+Convert(varchar(10),EmpID),StartMoney,
		SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,AcceptMoney,CheckMoney,EndMoney
		 from #tmpEmpPay'
	exec(@SStr)	--	业务员列表
	set @SStr='insert into #tmpListPay(AreaID,Num,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
		AcceptMoney,CheckMoney,EndMoney)'
	set @SStr=@SStr+' select AreaID,Convert(varchar(10),AreaID),StartMoney,
		SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,AcceptMoney,CheckMoney,EndMoney
		 from #tmpAreaPay'
	exec(@SStr)	--	地域列表

--插入销售统计起初表
	insert into tDetailOfSellReport(CustomerID,FirstMoney,SellMoney,BackMoney,AdjustMoney,RakeoffMoney,OtherMoney,
	GetMoney,TransMoney,LastMoney,EmpID,AreaID,Num,FullName) select CustomerID,StartMoney,SendMoney,BackMoney,TuneMoney,ReturnMoney,KeepMoney,
	AcceptMoney,CheckMoney,EndMoney,EmpID,AreaID,Num,FullName from #tmpListPay
	if @@ERROR!=0 goto Err_Proc
	update tDetailOfSellReport set ReportID=@ReportID where ReportID is null
	if @@ERROR!=0 goto Err_Proc

	--set @SqlStr='select * from #tmpListPay order by Num desc'
	--exec(@SqlStr)

	--commit tran
--select @ReportID
Suc_Proc:
	set nocount off
	return @ReportID
Err_Proc:
	--rollback tran
	set nocount off
	return -1	
Time_Proc:
	--rollback tran
	set nocount off
	return -2
end
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	保存指定模块的对象（中干/角色）的选择模块的权限配置数据。
参数：
	@pModelID	int		模块ID；
	@pObjID		varchar(5000)	对象ID；
	@pOperator	varchar(2000)	操作ID；
	@pRange		varchar(2000)	范围ID；
	@pObjType	varchar(2)	对象类别；（W-中干 R-角色）
返回：
	0	成功
	-1	失败
*/
CREATE PROCEDURE [Storage].[sp_SaveRightForModel](
	@pModelID	int,
	@pObjID		varchar(5000),
	@pOperator	varchar(2000),
	@pRange		varchar(2000),
	@pObjType	varchar(2)
) AS
BEGIN

	if(@pModelID = '')
		return 0

	declare @OneObjID varchar(20)
	declare @OneOperator varchar(50)
	declare @OneRange varchar(50)
	declare @i int
	declare @j int
	declare @k int
	declare @m int
	declare @tmpObjID varchar(2000)
	declare @tmpOperator varchar(2000)
	declare @tmpRange varchar(2000)

	declare @TypeID int

	set nocount on
	begin tran

	if(@pObjType = 'W')
		set @TypeID = 1
	else
		set @TypeID = 2

	/*删除原有配置数据*/
	delete from
		tRightList
	where
		 ModelID = @pModelID
		and ObjType = @TypeID

	if @@ERROR != 0 goto Err_Proc
	if @pObjID = '' goto Success_Proc


	select @tmpObjID = @pObjID
	select @tmpOperator = @pOperator
	select @tmpRange = @pRange

	/*写入新配置数据*/
	while(0=0)
	begin
		select @i=charindex(',',@tmpObjID)
		if(@i=0)
		begin
			insert into tRightList(ModelID,ObjID,ObjType,Operator,Range)
				 values(@pModelID,@tmpObjID,@TypeID,@tmpOperator,@tmpRange)
			if @@ERROR != 0 goto Err_Proc
			break
		end

		select @j = charindex('/',@tmpOperator)
		select @k = charindex('/',@tmpRange)

		select @OneObjID=left(@tmpObjID,@i-1)
		select @tmpObjID=right(@tmpObjID,len(@tmpObjID)-@i)

		select @OneOperator = left(@tmpOperator,@j-1)
		select @tmpOperator = right(@tmpOperator,len(@tmpOperator)-@j)

		select @OneRange = left(@tmpRange,@k-1)
		select @tmpRange = right(@tmpRange,len(@tmpRange)-@k)

		insert into tRightList(ModelID,ObjID,ObjType,Operator,Range)
			 values(@pModelID,@OneObjID,@TypeID,@OneOperator,@OneRange)

		if @@ERROR != 0 goto Err_Proc

	end

	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
Success_Proc:
	commit tran
	set nocount off
	return 0
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO

/*

功能：
	保存指定对象（中干/角色）的选择模块的权限配置数据。
参数：
	@pObjID		varchar(20)	对象ID；
	@pModelID	varchar(2000)	模块ID；
	@pOperator	varchar(2000)	操作ID；
	@pRange		varchar(2000)	范围ID；
返回：
	0	成功
	-1	失败
*/
CREATE PROCEDURE [Storage].[sp_SaveRightForObj](
	@pObjID		varchar(20),
	@pModelID	varchar(2000),
	@pOperator	varchar(2000),
	@pRange		varchar(2000),
	@pObjType	varchar(2),
	@pPModelID	int		--父模块
) AS
BEGIN
	

	if(@pObjID = '')
		return 0

	declare @OneModelID varchar(20)
	declare @OneOperator varchar(50)
	declare @OneRange varchar(50)
	declare @i int
	declare @j int
	declare @k int
	declare @m int
	declare @tmpModelID varchar(2000)
	declare @tmpOperator varchar(2000)
	declare @tmpRange varchar(2000)

	declare @TypeID int

	set nocount on
	begin tran

	if(@pObjType = 'W')
		set @TypeID = 1
	else
		set @TypeID = 2

	/*删除原有配置数据*/
	delete from
		 tRightList
	where
		 ObjID = @pObjID
		and ObjType = @TypeID
		and ModelID in (select ModelID from tModel where PModelID=@pPModelID)

	if @@ERROR != 0 goto Err_Proc
	if @pModelID = '' goto Success_Proc   --当选择的模块为空时就保存成功

	select @tmpModelID = @pModelID
	select @tmpOperator = @pOperator
	select @tmpRange = @pRange

	/*写入新配置数据*/
	while(0=0)
	begin
		select @i=charindex(',',@tmpModelID)
		if(@i=0)
		begin
			insert into tRightList(ModelID,ObjID,ObjType,Operator,Range)
				 

values(@tmpModelID,@pObjID,@TypeID,@tmpOperator,@tmpRange)
			if @@ERROR != 0 goto Err_Proc
			break
		end

		select @j = charindex('/',@tmpOperator)
		select @k = charindex('/',@tmpRange)

		select @OneModelID=left(@tmpModelID,@i-1)
		select @tmpModelID=right(@tmpModelID,len(@tmpModelID)-@i)

		select @OneOperator = left(@tmpOperator,@j-1)
		select @tmpOperator = right(@tmpOperator,len(@tmpOperator)-@j)

		select @OneRange = left(@tmpRange,@k-1)
		select @tmpRange = right(@tmpRange,len(@tmpRange)-@k)

		insert into tRightList(ModelID,ObjID,ObjType,Operator,Range)
			 values(@OneModelID,@pObjID,@TypeID,@OneOperator,@OneRange)

		if @@ERROR != 0 goto Err_Proc

	end

	commit tran
	set nocount off
	return 0
Err_Proc:
	rollback tran
	set nocount off
	return -1
Success_Proc:
	commit tran
	set nocount off
	return 0
END
GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	查询货品入库日动表。
参数：
	@pStoreHouseID	numeric		库房ID；（该库房及下级库房）
	@pGoodsClassID	numeric		货物分类ID；
	@pGoodsNO	varchar(20)	货品编号；
	@pGoodsName	varchar(100)	货品名称；
	@pStartDate	varchar(20)	开始日期；
	@pEndDate	varchar(20)	结束日期；
	@pPutinEmpID	numeric		入库人ID；
	@pStorerID	numeric		库管员ID；
	@pPutinType	int		入库类别；（0-正常入库　1-退货入库　2-盘盈入库）
	@pGoodsType	int		货物类别；（0-产品　1-半成品　2-成品）
返回：
	0	成功
	-1	失败
*/
CREATE  procedure [storage].[sp_StoreQueryPutin](
	@pRecNums		int output,	--记录数
	@pRecPages		int output,	--记录页数
	@pStoreHouseID	numeric,	--库房ID；（该库房及下级库房）（0表示所有）
	@pGoodsClassID	numeric,	--货物分类ID（0表示所有）；
	@pGoodsNO		varchar(20),	--货品编号；
	@pGoodsName	varchar(100),	--货品名称；
	@pStartDate		varchar(20),	--开始日期；
	@pEndDate		varchar(20),	--结束日期；
	@pPutinEmpID		numeric,	--入库人ID；
	@pStorerID		numeric,	--库管员ID；
	@pPutinType		int,		--入库类别；（0-正常入库　1-退货入库　2-盘盈入库）（99表示所有）
	@pGoodsType		int,		--货物类别；（0-产品　1-半成品　2-成品）
	@pCurPage		int = 1,
	@pPageSize		int = 20
)
AS
BEGIN

	set nocount on

	declare @strSQL varchar(8000)
	declare @strSQL1 varchar(8000)
	declare @strSQL2 varchar(8000)
	declare @P1 int,@P2 int,@P3 int,@P4 int

	set @strSQL1 = ''
	set @strSQL2 = ''

	--再过滤明细表中的货品
/*
/*select
		OT.GoodsID,
		OT.GoodsCode,
		OT.GoodsName,
		OT.Color,
		OT.UnitName,
		OT.ZoomoutPic,
		m.DataValue Model,
		s.DataValue Spec,
		OT.PutinNums,
		OT.AllMoney
	from
	(*/
*/
	set @strSQL = '
	select
		p.GoodsID,
		g.GoodsCode,
		g.GoodsName,
		--g.GoodsTypeID,
		g.Color,
		g.UnitName,
		g.ZoomoutPic,
		--p.ZoominPic,
		--p.CurStoreNums
		p.PutinNums,
		p.AllMoney,
		g.Model,
		g.Spec
	from
	(select
		GoodsID,
		sum(PutinNums) PutinNums,
		sum(AllMoney) AllMoney
	from
		tDetailOfPutin
	where
		Status = 1
		and GoodsType = ' + convert(varchar(20),@pGoodsType)

		--如果指定了库房，则按库房过滤货品
	if(@pStoreHouseID != 0)
		set @strSQL = @strSQL + ' and StoreHouseID in (select StoreHouseID from Storage.fnGetTreeStorageHouseTable(' + convert(varchar(20),@pStoreHouseID) + ',0,0))'

		--如果指定了货品分类或货品编号或货品名称，则过滤货品
	if((@pGoodsClassID != 0)  or (@pGoodsNO != '') or (@pGoodsName != '')) begin
		set @strSQL1 = 'select GoodsID from tGoods where GoodsType=' + convert(varchar(20),@pGoodsType)
		if(@pGoodsClassID != 0)
			set @strSQL1 = @strSQL1 + ' and GoodsTypeID in (select DataID from storage.fnGetBaseDataTreeTable(' + convert(varchar(20),@pGoodsClassID) + ',' + convert(varchar(20),@pGoodsType) + '))'
		if(@pGoodsNO != '')
			set @strSQL1 = @strSQL1 + ' and GoodsCode like ''%' + @pGoodsNO + '%'''
		if(@pGoodsName != '')
			set @strSQL1 = @strSQL1 + ' and GoodsName like ''%' + @pGoodsName + '%'''
	end

	if(@strSQL1 != '')
		set @strSQL = @strSQL + ' and GoodsID in (' + @strSQL1 + ')'

		--起始日期
	if(@pStartDate != '') begin
		if(@pEndDate != '') begin
			set @strSQL = @strSQL + ' and PutinTime between ''' + @pStartDate + ''' and ''' + @pEndDate + ''''
		end
		else
			set @strSQL = @strSQL + ' and PutinTime >= ''' + @pStartDate + ''''
	end
	else begin
		if(@pEndDate != '')
			set @strSQL = @strSQL + ' and PutinTime <= ''' + @pEndDate + ''''
	end

		--入库人、库管员
	if((@pPutinEmpID != 0) or (@pStorerID != 0)) begin
		set @strSQL2 = 'select BillOfPutinID from tBillOfPutin'
		if((@pPutinEmpID != 0) and (@pStorerID != 0))
			set @strSQL2 = @strSQL2 + ' where PutinEmpID = ' + convert(varchar(20),@pPutinEmpID) + ' and StorerID = ' + convert(varchar(20),@pStorerID)
		if((@pPutinEmpID != 0) and (@pStorerID = 0))
			set @strSQL2 = @strSQL2 + ' where PutinEmpID = ' + convert(varchar(20),@pPutinEmpID)
		if((@pPutinEmpID = 0) and (@pStorerID != 0))
			set @strSQL2 = @strSQL2 + ' where StorerID = ' + convert(varchar(20),@pStorerID)
	end

	if(@strSQL2 != '')
		set @strSQL = @strSQL + ' and BillOfPutinID in (' + @strSQL2 + ')'

		--入库类别
	if(@pPutinType != 99)
		set @strSQL = @strSQL + ' and PutinType=' + convert(varchar(20),@pPutinType)

	set @strSQL = @strSQL + '
 	group by GoodsID) p,tGoods g
	where
		p.GoodsID = g.GoodsID'
/*)


	 OT

	left outer join tBaseData m
	on OT.ModelID = m.DataID

	left outer join tBaseData s
	on OT.SpecID = s.DataID
*/

--	print @strSQL
--	exec(@strSQL)
	set @P2=8 --静态游标
	set @P3=1 --游标只读
	set @P4=100010 ---总的行数

	if(@pCurPage<=0)				--传入的当前页号小于0的意外处理
		set @pCurPage = 1

	exec sp_cursoropen @P1 output,@strSQL, @P2 output, @P3 output, @P4 output

	set @pRecNums = @P4				--记录数
	set @pRecPages = @pRecNums/@pPageSize
	if(@pRecNums % @pPageSize > 0)
		set @pRecPages = @pRecPages + 1		--页数

	if(@pCurPage >  @pRecPages)
		set @pCurPage = @pRecPages	--传入的当前页号大于总页数的情况的意外处理

	set @pCurPage = (@pCurPage-1)*@pPageSize+1

	exec sp_cursorfetch @P1,16,@pCurPage,@pPageSize
	exec sp_cursorclose @P1

	set nocount off
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


/*

功能：
	查询货品出库日动表。
参数：
	@pStoreHouseID	numeric		库房ID；（该库房及下级库房）
	@pGoodsClassID	numeric		货物分类ID；
	@pGoodsNO	varchar(20)		货品编号；
	@pGoodsName	varchar(100)	货品名称；
	@pStartDate	varchar(20)		开始日期；
	@pEndDate	varchar(20)		结束日期；
	@pTakeoutEmpID	numeric		出库人ID；
	@pStorerID	numeric			库管员ID；
	@pTakeoutType	int		出库类别；（0-正常出库　1-退货出库　2-盘盈出库）
	@pGoodsType	int			货物类别；（0-产品　1-半成品　2-成品）
返回：
	0	成功
	-1	失败
*/
CREATE  procedure [storage].[sp_StoreQueryTakeout](
	@pRecNums		int output,	--记录数
	@pRecPages		int output,	--记录页数
	@pStoreHouseID	numeric,	--库房ID；（该库房及下级库房）（0表示所有）
	@pGoodsClassID	numeric,	--货物分类ID（0表示所有）；
	@pGoodsNO		varchar(20),	--货品编号；
	@pGoodsName	varchar(100),	--货品名称；
	@pStartDate		varchar(20),	--开始日期；
	@pEndDate		varchar(20),	--结束日期；
	@pTakeoutEmpID	numeric,	--出库人ID；
	@pStorerID		numeric,	--库管员ID；
	@pTakeoutType	int,		--出库类别；（0-正常出库　1-退货出库　2-盘盈入库）（99表示所有）
	@pGoodsType		int,		--货物类别；（0-产品　1-半成品　2-成品）
	@pCurPage		int = 1,
	@pPageSize		int = 20
)
AS
BEGIN

	set nocount on

	declare @strSQL varchar(8000)
	declare @strSQL1 varchar(8000)
	declare @strSQL2 varchar(8000)
	declare @P1 int,@P2 int,@P3 int,@P4 int

	set @strSQL1 = ''
	set @strSQL2 = ''

	--再过滤明细表中的货品
	set @strSQL = '
	select
		p.GoodsID,
		g.GoodsCode,
		g.GoodsName,
		--g.GoodsTypeID,
		g.Color,
		g.UnitName,
		g.ZoomoutPic,
		--p.ZoominPic,
		--p.CurStoreNums
		p.TakeoutNums,
		p.AllMoney,
		g.Model,
		g.Spec
	from
	(select
		GoodsID,
		sum(OutNums) TakeoutNums,
		sum(AllMoney) AllMoney
	from
		tDetailOfTakeout
	where
		Status = 1
		and GoodsType = ' + convert(varchar(20),@pGoodsType)

		--如果指定了库房，则按库房过滤货品
	if(@pStoreHouseID != 0)
		set @strSQL = @strSQL + ' and StoreHouseID in (select StoreHouseID from Storage.fnGetTreeStorageHouseTable(' + convert(varchar(20),@pStoreHouseID) + ',0,0))'

		--如果指定了货品分类或货品编号或货品名称，则过滤货品
	if((@pGoodsClassID != 0)  or (@pGoodsNO != '') or (@pGoodsName != '')) begin
		set @strSQL1 = 'select GoodsID from tGoods where GoodsType=' + convert(varchar(20),@pGoodsType)
		if(@pGoodsClassID != 0)
			set @strSQL1 = @strSQL1 + ' and GoodsTypeID in (select DataID from storage.fnGetBaseDataTreeTable(' + convert(varchar(20),@pGoodsClassID) + ',' + convert(varchar(20),@pGoodsType) + '))'
		if(@pGoodsNO != '')
			set @strSQL1 = @strSQL1 + ' and GoodsCode like ''%' + @pGoodsNO + '%'''
		if(@pGoodsName != '')
			set @strSQL1 = @strSQL1 + ' and GoodsName like ''%' + @pGoodsName + '%'''
	end

	if(@strSQL1 != '')
		set @strSQL = @strSQL + ' and GoodsID in (' + @strSQL1 + ')'

		--起始日期
	if(@pStartDate != '') begin
		if(@pEndDate != '') begin
			set @strSQL = @strSQL + ' and TakeoutTime between ''' + @pStartDate + ''' and ''' + @pEndDate + ''''
		end
		else
			set @strSQL = @strSQL + ' and TakeoutTime >= ''' + @pStartDate + ''''
	end
	else begin
		if(@pEndDate != '')
			set @strSQL = @strSQL + ' and PutinTime <= ''' + @pEndDate + ''''
	end

		--入库人、库管员
	if((@pTakeoutEmpID != 0) or (@pStorerID != 0)) begin
		set @strSQL2 = 'select BillOfPutinID from tBillOfPutin'
		if((@pTakeoutEmpID != 0) and (@pStorerID != 0))
			set @strSQL2 = @strSQL2 + ' where PutinEmpID = ' + convert(varchar(20),@pTakeoutEmpID) + ' and StorerID = ' + convert(varchar(20),@pStorerID)
		if((@pTakeoutEmpID != 0) and (@pStorerID = 0))
			set @strSQL2 = @strSQL2 + ' where PutinEmpID = ' + convert(varchar(20),@pTakeoutEmpID)
		if((@pTakeoutEmpID = 0) and (@pStorerID != 0))
			set @strSQL2 = @strSQL2 + ' where StorerID = ' + convert(varchar(20),@pStorerID)
	end

	if(@strSQL2 != '')
		set @strSQL = @strSQL + ' and BillOfTakeoutID in (' + @strSQL2 + ')'

		--入库类别
	if(@pTakeoutType != 99)
		set @strSQL = @strSQL + ' and TakeoutType=' + convert(varchar(20),@pTakeoutType)

	set @strSQL = @strSQL + '
 	group by GoodsID) p,tGoods g
	where
		p.GoodsID = g.GoodsID'

	set @P2=8 --静态游标
	set @P3=1 --游标只读
	set @P4=100010 ---总的行数

	if(@pCurPage<=0)				--传入的当前页号小于0的意外处理
		set @pCurPage = 1

	exec sp_cursoropen @P1 output,@strSQL, @P2 output, @P3 output, @P4 output

	set @pRecNums = @P4				--记录数
	set @pRecPages = @pRecNums/@pPageSize
	if(@pRecNums % @pPageSize > 0)
		set @pRecPages = @pRecPages + 1		--页数

	if(@pCurPage >  @pRecPages)
		set @pCurPage = @pRecPages	--传入的当前页号大于总页数的情况的意外处理

	set @pCurPage = (@pCurPage-1)*@pPageSize+1

	exec sp_cursorfetch @P1,16,@pCurPage,@pPageSize
	exec sp_cursorclose @P1

	set nocount off
END

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

setuser N'Storage'
GO


CREATE  procedure [storage].[sp_productList] --分页显示产品列表
	@MaxPage int output,      --最大页数
                @WhereStr varchar(200)='',  --传入Where条件
	@pagesize int =10,  --每页显示的条数
	@curPage int =1  --当前显示的页数
 as

set nocount off



	declare @PageStart int
	declare @PageEnd  int

	set @PageStart=(@curPage-1)*@pagesize --设置显示其实区域
	set @PageEnd=@PageStart+@pagesize --设置显示终止区域

	declare @maxCount int
               
               declare @SQL varchar(1000)
                create table #tempTable(tempID int Identity(1,1) not null,nid int);
	set  @SQL='insert into #tempTable (nid) select GoodsID from Tgoods  '+@whereStr+';'
                exec(@SQL)

            	      select @maxCount=@@rowcount

	           if((@maxCount  % @pagesize)>0)
	                set @MaxPage=@maxCount / @pagesize + 1
	           else
	                set @MaxPage=@maxCount / @pagesize

	         if(@MaxPage=0)
	        	 set @MaxPage=1
                        
set nocount on

	set @SQL='select  Tgoods.GoodsID,Tgoods.GoodsCode, Tgoods.GoodsName, Tgoods.Color, Tgoods.Model, Tgoods.Spec, Tgoods.CurStoreNums,Tgoods.Price,Tgoods.memo from Tgoods   join #tempTable '
                set @SQL=@SQL+' on Tgoods.goodsID=#tempTable.nid and #tempTable.tempID>'+str(@PageStart)+' and #tempTable.tempID<='+str(@PageEnd)+' '+@WhereStr
exec(@SQL)
  	

 return @MaxPage

GO
setuser
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

