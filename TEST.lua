local _0=function(s)return(s:gsub("%%(%x%x)",function(h)return string.char(tonumber(h,16))end))end
local _1=game:GetService(_0("%50%6C%61%79%65%72%73"))
local _2=game:GetService(_0("%55%73%65%72%49%6E%70%75%74%53%65%72%76%69%63%65"))
local _3=game:GetService(_0("%53%74%61%72%74%65%72%47%75%69"))
local _4=game:GetService(_0("%4D%61%72%6B%65%74%70%6C%61%63%65%53%65%72%76%69%63%65"))
local _5=_1.LocalPlayer
local _6=_5:WaitForChild(_0("%50%6C%61%79%65%72%47%75%69"))
local _7={[142823291]=true,[121787682648572]=true}
local _8=function(_a,_b)pcall(function()_3:SetCore(_0("%53%65%6E%64%4E%6F%74%69%66%69%63%61%74%69%6F%6E"),{Title=_a,Text=_b,Duration=5})end)end
local _9=function()
    if _7[game.PlaceId]then return true,_0("%50%6C%61%63%65%49%64%20%6D%61%74%63%68%65%64")end
    local _c,_d=pcall(function()return _4:GetProductInfo(game.PlaceId).Name end)
    if _c and _d then
        if string.find(string.lower(_d),_0("%6D%75%72%64%65%72%20%6D%79%73%74%65%72%79%20%32"),1,true)then
            return true,_0("%4E%61%6D%65%20%6D%61%74%63%68%65%64")
        end
        return false,_0("%43%75%72%72%65%6E%74%20%67%61%6D%65%3A%20")..tostring(_d)
    end
    return false,_0("%43%6F%75%6C%64%20%6E%6F%74%20%76%65%72%69%66%79%20%67%61%6D%65%20%6E%61%6D%65")
end
for _, _e in ipairs({_0("%53%63%72%69%70%74%73%42%79%41%72%62%75%7A"),_0("%4D%4D%32%4D%65%6E%75%42%79%41%72%62%75%7A")})do
    local _f=_6:FindFirstChild(_e)
    if _f then _f:Destroy()end
end
local _10=Instance.new(_0("%53%63%72%65%65%6E%47%75%69"))
_10.Name=_0("%53%63%72%69%70%74%73%42%79%41%72%62%75%7A")
_10.ResetOnSpawn=false
_10.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
_10.IgnoreGuiInset=false
_10.Enabled=true
_10.DisplayOrder=100
_10.Parent=_6
local _11=Instance.new(_0("%46%72%61%6D%65"))
_11.Name=_0("%4D%61%69%6E")
_11.Size=UDim2.fromOffset(280,330)
_11.Position=UDim2.new(0.5,-140,0.5,-165)
_11.BackgroundColor3=Color3.fromRGB(22,23,28)
_11.BorderSizePixel=0
_11.Visible=true
_11.Active=true
_11.Parent=_10
local _12=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_12.CornerRadius=UDim.new(0,12)
_12.Parent=_11
local _13=Instance.new(_0("%55%49%53%74%72%6F%6B%65"))
_13.Color=Color3.fromRGB(55,57,65)
_13.Thickness=1
_13.Parent=_11
local _14=Instance.new(_0("%46%72%61%6D%65"))
_14.Name=_0("%48%65%61%64%65%72")
_14.Size=UDim2.new(1,0,0,48)
_14.BackgroundColor3=Color3.fromRGB(29,30,37)
_14.BorderSizePixel=0
_14.Active=true
_14.Parent=_11
local _15=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_15.CornerRadius=UDim.new(0,12)
_15.Parent=_14
local _16=Instance.new(_0("%54%65%78%74%4C%61%62%65%6C"))
_16.Name=_0("%54%69%74%6C%65")
_16.Size=UDim2.new(1,-120,1,0)
_16.Position=UDim2.fromOffset(10,0)
_16.BackgroundTransparency=1
_16.Text=_0("%53%43%52%49%50%54%53%20%42%59%20%41%52%42%55%5A")
_16.TextColor3=Color3.fromRGB(245,245,250)
_16.TextSize=12
_16.Font=Enum.Font.GothamBold
_16.TextXAlignment=Enum.TextXAlignment.Left
_16.TextYAlignment=Enum.TextYAlignment.Center
_16.ZIndex=2
_16.Parent=_14
local _17=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
_17.Name=_0("%43%6C%6F%73%65")
_17.Size=UDim2.fromOffset(30,30)
_17.Position=UDim2.new(1,-105,0.5,-15)
_17.BackgroundColor3=Color3.fromRGB(42,44,52)
_17.Text=_0("%58")
_17.TextSize=16
_17.TextColor3=Color3.fromRGB(255,200,200)
_17.Font=Enum.Font.GothamBold
_17.BorderSizePixel=0
_17.AutoButtonColor=false
_17.Active=true
_17.ZIndex=5
_17.Parent=_14
local _18=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_18.CornerRadius=UDim.new(0,7)
_18.Parent=_17
local _19=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
_19.Name=_0("%4C%6F%63%6B")
_19.Size=UDim2.fromOffset(30,30)
_19.Position=UDim2.new(1,-70,0.5,-15)
_19.BackgroundColor3=Color3.fromRGB(42,44,52)
_19.Text=_0("%F0%9F%94%93")
_19.TextSize=14
_19.TextColor3=Color3.new(1,1,1)
_19.Font=Enum.Font.GothamBold
_19.BorderSizePixel=0
_19.AutoButtonColor=false
_19.Active=true
_19.ZIndex=5
_19.Parent=_14
local _1a=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_1a.CornerRadius=UDim.new(0,7)
_1a.Parent=_19
local _1b=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
_1b.Name=_0("%4D%69%6E%69%6D%69%7A%65")
_1b.Size=UDim2.fromOffset(30,30)
_1b.Position=UDim2.new(1,-35,0.5,-15)
_1b.BackgroundColor3=Color3.fromRGB(42,44,52)
_1b.Text=_0("%2D")
_1b.TextColor3=Color3.new(1,1,1)
_1b.TextSize=17
_1b.Font=Enum.Font.GothamBold
_1b.BorderSizePixel=0
_1b.AutoButtonColor=false
_1b.Active=true
_1b.ZIndex=5
_1b.Parent=_14
local _1c=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_1c.CornerRadius=UDim.new(0,7)
_1c.Parent=_1b
local _1d=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
_1d.Name=_0("%52%65%73%69%7A%65%48%61%6E%64%6C%65")
_1d.Size=UDim2.fromOffset(16,16)
_1d.Position=UDim2.new(1,-16,1,-16)
_1d.BackgroundColor3=Color3.fromRGB(55,57,65)
_1d.BorderSizePixel=0
_1d.Text=_0("")
_1d.AutoButtonColor=false
_1d.Active=true
_1d.ZIndex=30
_1d.Parent=_11
local _1e=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_1e.CornerRadius=UDim.new(0,4)
_1e.Parent=_1d
local _1f=240
local _20=200
local _21=false
local _22
local _23
_1d.InputBegan:Connect(function(_24)
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _21=true
        _22=_24.Position
        _23=_11.AbsoluteSize
    end
end)
_2.InputChanged:Connect(function(_24)
    if not _21 then return end
    if _24.UserInputType==Enum.UserInputType.MouseMovement or _24.UserInputType==Enum.UserInputType.Touch then
        local _25=_24.Position-_22
        local _26=math.max(_1f,_23.X+_25.X)
        local _27=math.max(_20,_23.Y+_25.Y)
        _11.Size=UDim2.fromOffset(_26,_27)
    end
end)
_2.InputEnded:Connect(function(_24)
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _21=false
    end
end)
local _28=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
_28.Name=_0("%52%65%6F%70%65%6E")
_28.Size=UDim2.fromOffset(50,50)
_28.Position=UDim2.new(0,15,0.5,-25)
_28.BackgroundColor3=Color3.fromRGB(29,30,37)
_28.BorderSizePixel=0
_28.Text=_0("%41%52%42")
_28.TextColor3=Color3.fromRGB(245,245,250)
_28.TextSize=13
_28.Font=Enum.Font.GothamBold
_28.AutoButtonColor=false
_28.Active=true
_28.Visible=false
_28.ZIndex=50
_28.Parent=_10
local _29=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_29.CornerRadius=UDim.new(1,0)
_29.Parent=_28
local _2a=Instance.new(_0("%55%49%53%74%72%6F%6B%65"))
_2a.Color=Color3.fromRGB(80,82,90)
_2a.Thickness=2
_2a.Parent=_28
local _2b=Instance.new(_0("%53%63%72%6F%6C%6C%69%6E%67%46%72%61%6D%65"))
_2b.Name=_0("%43%6F%6E%74%65%6E%74")
_2b.Size=UDim2.new(1,-20,1,-58)
_2b.Position=UDim2.fromOffset(10,53)
_2b.BackgroundTransparency=1
_2b.BorderSizePixel=0
_2b.ScrollBarThickness=5
_2b.ScrollBarImageColor3=Color3.fromRGB(75,77,85)
_2b.CanvasSize=UDim2.fromOffset(0,0)
_2b.AutomaticCanvasSize=Enum.AutomaticSize.Y
_2b.ScrollingDirection=Enum.ScrollingDirection.Y
_2b.Parent=_11
local _2c=Instance.new(_0("%55%49%4C%69%73%74%4C%61%79%6F%75%74"))
_2c.Padding=UDim.new(0,6)
_2c.SortOrder=Enum.SortOrder.LayoutOrder
_2c.Parent=_2b
local _2d=0
local _2e=function()
    _2d=_2d+1
    return _2d
end
local _2f=function(_30)
    local _31=Instance.new(_0("%54%65%78%74%4C%61%62%65%6C"))
    _31.Name=_30.._0("%48%65%61%64%65%72")
    _31.Size=UDim2.new(1,0,0,20)
    _31.BackgroundTransparency=1
    _31.Text=_30
    _31.TextColor3=Color3.fromRGB(150,153,165)
    _31.TextSize=11
    _31.Font=Enum.Font.GothamBold
    _31.TextXAlignment=Enum.TextXAlignment.Left
    _31.LayoutOrder=_2e()
    _31.Parent=_2b
    return _31
end
local _32=function(_33,_34)
    local _35=Instance.new(_0("%54%65%78%74%42%75%74%74%6F%6E"))
    _35.Name=_33
    _35.Size=UDim2.new(1,0,0,40)
    _35.BackgroundColor3=Color3.fromRGB(34,36,43)
    _35.BorderSizePixel=0
    _35.Text=_34
    _35.TextColor3=Color3.fromRGB(230,230,235)
    _35.TextSize=13
    _35.Font=Enum.Font.GothamSemibold
    _35.AutoButtonColor=false
    _35.LayoutOrder=_2e()
    _35.Parent=_2b
    local _36=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
    _36.CornerRadius=UDim.new(0,8)
    _36.Parent=_35
    local _37=Instance.new(_0("%46%72%61%6D%65"))
    _37.Name=_0("%49%6E%64%69%63%61%74%6F%72")
    _37.Size=UDim2.fromOffset(5,20)
    _37.Position=UDim2.fromOffset(8,10)
    _37.BackgroundColor3=Color3.fromRGB(80,82,90)
    _37.BorderSizePixel=0
    _37.Parent=_35
    local _38=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
    _38.CornerRadius=UDim.new(1,0)
    _38.Parent=_37
    _35.MouseEnter:Connect(function()_35.BackgroundColor3=Color3.fromRGB(45,47,56)end)
    _35.MouseLeave:Connect(function()_35.BackgroundColor3=Color3.fromRGB(34,36,43)end)
    return _35,_37
end
local _39=Instance.new(_0("%54%65%78%74%42%6F%78"))
_39.Name=_0("%53%65%61%72%63%68%42%6F%78")
_39.Size=UDim2.new(1,0,0,36)
_39.BackgroundColor3=Color3.fromRGB(34,36,43)
_39.BorderSizePixel=0
_39.Text=_0("")
_39.PlaceholderText=_0("%53%65%61%72%63%68%20%73%63%72%69%70%74%73%2E%2E%2E")
_39.PlaceholderColor3=Color3.fromRGB(150,153,165)
_39.TextColor3=Color3.fromRGB(230,230,235)
_39.TextSize=13
_39.Font=Enum.Font.GothamSemibold
_39.ClearTextOnFocus=false
_39.LayoutOrder=_2e()
_39.Parent=_2b
local _3a=Instance.new(_0("%55%49%43%6F%72%6E%65%72"))
_3a.CornerRadius=UDim.new(0,8)
_3a.Parent=_39
local _3b=Instance.new(_0("%55%49%50%61%64%64%69%6E%67"))
_3b.PaddingLeft=UDim.new(0,10)
_3b.PaddingRight=UDim.new(0,10)
_3b.Parent=_39
_2f(_0("%53%43%52%49%50%54%53"))
local _3c={}
local _3d=function(_3e,_3f)
    table.insert(_3c,{Name=_3e,Button=_3f})
end
local _40=true
local _41=function()
    _40=true
    _11.Visible=true
    _28.Visible=false
end
local _42=function()
    _40=false
    _11.Visible=false
    _28.Visible=true
end
local _43,_44=_32(_0("%4D%4D%32"),_0("%4D%4D%32"))
_44.BackgroundColor3=Color3.fromRGB(230,55,55)
local _45=Instance.new(_0("%54%65%78%74%4C%61%62%65%6C"))
_45.Name=_0("%53%75%62%4C%61%62%65%6C")
_45.Size=UDim2.new(1,-30,0,12)
_45.Position=UDim2.new(0,22,1,-14)
_45.BackgroundTransparency=1
_45.Text=_0("%4D%75%72%64%65%72%20%4D%79%73%74%65%72%79%20%32%20%6F%6E%6C%79")
_45.TextColor3=Color3.fromRGB(150,153,165)
_45.TextSize=10
_45.Font=Enum.Font.GothamBold
_45.TextXAlignment=Enum.TextXAlignment.Left
_45.ZIndex=3
_45.Parent=_43
local _46=function()
    _43.Text=_0("%4D%4D%32")
    _43.TextColor3=Color3.fromRGB(230,230,235)
    _44.BackgroundColor3=Color3.fromRGB(230,55,55)
end
_43.MouseButton1Click:Connect(function()
    local _47,_48=_9()
    if not _47 then
        _43.Text=_0("%57%72%6F%6E%67%20%67%61%6D%65")
        _43.TextColor3=Color3.fromRGB(255,100,100)
        _44.BackgroundColor3=Color3.fromRGB(255,100,100)
        _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%4D%4D%32%20%6F%6E%6C%79%20%77%6F%72%6B%73%20%69%6E%20%4D%75%72%64%65%72%20%4D%79%73%74%65%72%79%20%32%2E%0A")..tostring(_48))
        warn(_0("%5B%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A%5D%20%4E%6F%74%20%69%6E%20%4D%4D%32%20%2D%20")..tostring(_48))
        task.wait(2)
        _46()
        return
    end
    _43.Text=_0("%44%6F%77%6E%6C%6F%61%64%69%6E%67%2E%2E%2E")
    _43.TextColor3=Color3.fromRGB(255,205,50)
    _44.BackgroundColor3=Color3.fromRGB(255,205,50)
    local _49=_0("%68%74%74%70%73%3A%2F%2F%72%61%77%2E%67%69%74%68%75%62%75%73%65%72%63%6F%6E%74%65%6E%74%2E%63%6F%6D%2F%61%72%62%75%7A%31%38%31%70%6C%2F%4D%4D%32%2D%4D%45%4E%55%2D%42%59%2D%41%52%42%55%5A%2F%72%65%66%73%2F%68%65%61%64%73%2F%6D%61%69%6E%2F%4D%4D%32%4D%45%4E%55%2E%6C%75%61")
    local _4a,_4b=pcall(function()return game:HttpGet(_49.._0("%3F%76%3D")..tick())end)
    if not _4a then
        _43.Text=_0("%44%6F%77%6E%6C%6F%61%64%20%66%61%69%6C%65%64")
        _43.TextColor3=Color3.fromRGB(255,100,100)
        _44.BackgroundColor3=Color3.fromRGB(255,100,100)
        _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%46%61%69%6C%65%64%20%74%6F%20%64%6F%77%6E%6C%6F%61%64%20%4D%4D%32%20%73%63%72%69%70%74%2E%0A")..tostring(_4b))
        warn(_0("%5B%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A%5D%20%48%74%74%70%47%65%74%20%66%61%69%6C%65%64%3A"),_4b)
        task.wait(3)
        _46()
        return
    end
    if not _4b or #_4b==0 then
        _43.Text=_0("%45%6D%70%74%79%20%66%69%6C%65")
        _43.TextColor3=Color3.fromRGB(255,100,100)
        _44.BackgroundColor3=Color3.fromRGB(255,100,100)
        _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%44%6F%77%6E%6C%6F%61%64%65%64%20%66%69%6C%65%20%69%73%20%65%6D%70%74%79%2E%20%43%68%65%63%6B%20%74%68%65%20%55%52%4C%2E"))
        warn(_0("%5B%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A%5D%20%44%6F%77%6E%6C%6F%61%64%65%64%20%63%6F%6E%74%65%6E%74%20%69%73%20%65%6D%70%74%79"))
        task.wait(3)
        _46()
        return
    end
    _43.Text=_0("%43%6F%6D%70%69%6C%69%6E%67%2E%2E%2E")
    _43.TextColor3=Color3.fromRGB(255,205,50)
    _44.BackgroundColor3=Color3.fromRGB(255,205,50)
    local _4c,_4d=loadstring(_4b)
    if not _4c then
        _43.Text=_0("%43%6F%6D%70%69%6C%65%20%65%72%72%6F%72")
        _43.TextColor3=Color3.fromRGB(255,100,100)
        _44.BackgroundColor3=Color3.fromRGB(255,100,100)
        _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%4D%4D%32%20%73%63%72%69%70%74%20%68%61%73%20%61%20%73%79%6E%74%61%78%20%65%72%72%6F%72%2E%20%43%68%65%63%6B%20%46%39%2E"))
        warn(_0("%5B%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A%5D%20%43%6F%6D%70%69%6C%65%20%65%72%72%6F%72%3A"),_4d)
        task.wait(3)
        _46()
        return
    end
    _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%4C%6F%61%64%69%6E%67%20%4D%4D%32%2E%2E%2E"))
    _10:Destroy()
    task.wait(0.1)
    task.spawn(function()
        local _4e,_4f=pcall(_4c)
        if not _4e then
            warn(_0("%5B%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A%5D%20%4D%4D%32%20%72%75%6E%74%69%6D%65%20%65%72%72%6F%72%3A"),_4f)
            pcall(function()
                _3:SetCore(_0("%53%65%6E%64%4E%6F%74%69%66%69%63%61%74%69%6F%6E"),{Title=_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),Text=_0("%4D%4D%32%20%73%63%72%69%70%74%20%63%72%61%73%68%65%64%2E%20%43%68%65%63%6B%20%46%39%2E"),Duration=5})
            end)
        end
    end)
end)
_3d(_0("%4D%4D%32"),_43)
_39:GetPropertyChangedSignal(_0("%54%65%78%74")):Connect(function()
    local _50=string.lower(_39.Text)
    for _,_51 in ipairs(_3c)do
        if _51.Button and _51.Button.Parent then
            local _52=_50==_0("") or string.find(string.lower(_51.Name),_50,1,true)
            _51.Button.Visible=_52
        end
    end
end)
local _53=false
local _54=false
local _55
local _56
_14.InputBegan:Connect(function(_24)
    if _53 then return end
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _54=true
        _55=_24.Position
        _56=_11.Position
    end
end)
_2.InputChanged:Connect(function(_24)
    if not _54 or _53 then return end
    if _24.UserInputType==Enum.UserInputType.MouseMovement or _24.UserInputType==Enum.UserInputType.Touch then
        local _25=_24.Position-_55
        _11.Position=UDim2.new(_56.X.Scale,_56.X.Offset+_25.X,_56.Y.Scale,_56.Y.Offset+_25.Y)
    end
end)
_2.InputEnded:Connect(function(_24)
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _54=false
    end
end)
local _57=false
_19.MouseButton1Click:Connect(function()
    _53=not _53
    if _53 then
        _19.Text=_0("%F0%9F%94%92")
        _19.BackgroundColor3=Color3.fromRGB(70,45,45)
    else
        _19.Text=_0("%F0%9F%94%93")
        _19.BackgroundColor3=Color3.fromRGB(42,44,52)
    end
end)
_1b.MouseButton1Click:Connect(function()
    _57=not _57
    if _57 then
        _2b.Visible=false
        _11.Size=UDim2.fromOffset(280,48)
        _1b.Text=_0("%2B")
    else
        _2b.Visible=true
        _11.Size=UDim2.fromOffset(280,330)
        _1b.Text=_0("%2D")
    end
end)
_17.MouseButton1Click:Connect(function()
    _42()
    _8(_0("%53%63%72%69%70%74%73%20%62%79%20%41%72%62%75%7A"),_0("%4C%61%75%6E%63%68%65%72%20%63%6C%6F%73%65%64%2E%20%50%72%65%73%73%20%52%69%67%68%74%20%53%68%69%66%74%20%74%6F%20%72%65%6F%70%65%6E%2E"))
end)
_17.MouseEnter:Connect(function()_17.BackgroundColor3=Color3.fromRGB(180,55,55)end)
_17.MouseLeave:Connect(function()_17.BackgroundColor3=Color3.fromRGB(42,44,52)end)
_28.MouseButton1Click:Connect(function()_41()end)
_2.InputBegan:Connect(function(_24,_58)
    if _58 then return end
    if _24.KeyCode==Enum.KeyCode.RightShift then
        if not _10.Parent then return end
        if _40 then _42() else _41() end
    end
end)
local _59=false
local _5a
local _5b
_28.InputBegan:Connect(function(_24)
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _59=true
        _5a=_24.Position
        _5b=_28.Position
    end
end)
_2.InputChanged:Connect(function(_24)
    if not _59 then return end
    if _24.UserInputType==Enum.UserInputType.MouseMovement or _24.UserInputType==Enum.UserInputType.Touch then
        local _25=_24.Position-_5a
        _28.Position=UDim2.new(_5b.X.Scale,_5b.X.Offset+_25.X,_5b.Y.Scale,_5b.Y.Offset+_25.Y)
    end
end)
_2.InputEnded:Connect(function(_24)
    if _24.UserInputType==Enum.UserInputType.MouseButton1 or _24.UserInputType==Enum.UserInputType.Touch then
        _59=false
    end
end)