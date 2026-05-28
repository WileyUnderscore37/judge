
local drawing = false

local rt = GetRenderTarget("bulletholes-testing2", ScrW(), ScrH())
local vecHull = Vector(2, 2, 2)
local coltransparent = Color(0, 0, 0, 0)

local center = Vector()
local timershit = 0

hg.ConVars = hg.ConVars or {}

local hg_bulletholesfps = CreateConVar("hg_bulletholesfps", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED, "How much fps should the view inside bullet holes be (0 = max)", 0, 300)
local hg_bulletholes = CreateConVar("hg_bulletholes", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED, "Enable R6S bulletholes feature", 0, 1)

hook.Add("PostRender", "sadasdsad", function()
    if !hg_bulletholes:GetBool() then return end
    local holes = GetNetVar("BulletHoles")
    local view = render.GetViewSetup()

    if !holes then return end
    local any = false

    for i = 1, #holes do
        local tbl = holes[i]

        if !tbl.pos1 then continue end
        local normf = tbl.dir:Forward()
        local dot = (tbl.pos1 - view.origin):GetNormalized():Dot(normf)
        --if dot < 0 then continue end
        local dot2 = view.angles:Forward():Dot(normf)

        tbl.dot = dot
        tbl.dot2 = dot2

        if dot > 0.5 and dot2 > 0.5 then
            any = true
        end
    end
    
    if any and timershit < CurTime() then
        timershit = CurTime() + ((hg_bulletholesfps:GetInt() == 0) and 0 or (1 / hg_bulletholesfps:GetInt()))
        
        local tr = {
            start = view.origin,
            endpos = view.angles:Forward() * 8000,
            mins = -vecHull,
            maxs = vecHull,
            filter = {lply},
        }
        
        local trace = util.TraceHull(tr)
        local pos = trace.HitPos
    
        local len = (view.origin - pos):Length() + 25
        
        render.PushRenderTarget( rt )
        
        drawing = true
        
        render.RenderView({
            znear = len,
            //origin = pos + view.angles:Forward() * add,
            drawhud = false,
            drawmonitors = false,
            drawviewer = false,
            drawviewmodel = false,
            viewid = VIEW_MONITOR,
            --x = 500,
            --y = 250,
            --w = 1000,
            --h = 500,
        })
        
        drawing = false
    
        render.PopRenderTarget()
    end
end)

hook.Add("PreDrawEffects","bulletholes-test",function()
    if !hg_bulletholes:GetBool() then return end
    local holes = GetNetVar("BulletHoles")
    
    if !holes then return end
    if drawing then return end

    local view = render.GetViewSetup()

    render.SetStencilWriteMask( 0xFF )
    render.SetStencilTestMask( 0xFF )
    render.SetStencilReferenceValue( 0 )
    render.SetStencilPassOperation( STENCIL_KEEP )
    render.SetStencilZFailOperation( STENCIL_KEEP )
    render.ClearStencil()

    render.SetStencilEnable( true )
    render.SetStencilReferenceValue( 1 )
    render.SetStencilCompareFunction( STENCIL_NEVER )
    render.SetStencilFailOperation( STENCIL_KEEP )
    render.SetStencilPassOperation( STENCIL_REPLACE )

    render.SetStencilReferenceValue( 1 )
    render.SetStencilCompareFunction( STENCIL_ALWAYS )
    render.SetStencilPassOperation( STENCIL_REPLACE )
    render.SetStencilZFailOperation( STENCIL_KEEP )
    render.SetStencilFailOperation( STENCIL_KEEP )

    render.SetColorMaterial()
    
    for i = 1, #holes do
        local tbl = holes[i]
        local ent = tbl[6]
        if !(IsValid(ent) or (ent and ent:IsWorld())) then continue end
        local pos, dir, pen, hitnormal, pen2 = tbl[1], tbl[2], tbl[3], tbl[4], tbl[5]

        if (!ent:IsWorld() and ((!tbl.lastpos or !tbl.lastpos:IsEqualTol(ent:GetPos(), 0.1)) or (!tbl.lastang or !tbl.lastang:IsEqualTol(ent:GetAngles(), 0.1)))) or !tbl.pos1 then
            local pos, dir = LocalToWorld(pos, dir, ent:GetPos(), ent:GetAngles())
            local _, hitnormal = LocalToWorld(vector_origin, hitnormal, vector_origin, ent:GetAngles())
        
            local up, right = dir:Up() * pen2, -dir:Right() * pen2
            local pos1 = pos + up * 0.5 - right * 0.5
            local pos1, pos2, pos3, pos4 = pos1, pos1 - up, pos1 - up + right, pos1 + right
            
            local pos1 = util.IntersectRayWithPlane(pos1 - dir:Forward() * 50, dir:Forward() * 100, pos, hitnormal:Forward()) or pos1
            local pos2 = util.IntersectRayWithPlane(pos2 - dir:Forward() * 50, dir:Forward() * 100, pos, hitnormal:Forward()) or pos2
            local pos3 = util.IntersectRayWithPlane(pos3 - dir:Forward() * 50, dir:Forward() * 100, pos, hitnormal:Forward()) or pos3
            local pos4 = util.IntersectRayWithPlane(pos4 - dir:Forward() * 50, dir:Forward() * 100, pos, hitnormal:Forward()) or pos4

            local pos5, pos6, pos7, pos8 = pos1 + dir:Forward() * pen, pos2 + dir:Forward() * pen, pos3 + dir:Forward() * pen, pos4 + dir:Forward() * pen
            
            tbl.lastpos = ent:GetPos()
            tbl.lastang = ent:GetAngles()

            if !pos1 or !pos2 or !pos3 or !pos4 then
                tbl.pos1 = nil
                
                continue
            end

            pos1:Add(hitnormal:Forward() * 0.01)
            pos2:Add(hitnormal:Forward() * 0.01)
            pos3:Add(hitnormal:Forward() * 0.01)
            pos4:Add(hitnormal:Forward() * 0.01)

            local addthing = hitnormal:Forward() * 0.09

            up:Mul(4)
            right:Mul(4)

            local pos11, pos21, pos31, pos41 = pos1 + addthing + up * 0.1 - right * 0.1,pos2 + addthing - up * 0.1 - right * 0.1,pos3 + addthing - up * 0.1 + right * 0.1, pos4 + addthing + right * 0.1
            
            tbl.pos1 = pos1
            tbl.pos2 = pos2
            tbl.pos3 = pos3
            tbl.pos4 = pos4
            tbl.pos5 = pos5
            tbl.pos6 = pos6
            tbl.pos7 = pos7
            tbl.pos8 = pos8
            tbl.pos11 = pos11
            tbl.pos21 = pos21
            tbl.pos31 = pos31
            tbl.pos41 = pos41
            tbl.pos = pos
            tbl.dir = dir
            tbl.hitnormal = hitnormal
        end
        
        render.DrawQuad(tbl.pos1, tbl.pos2, tbl.pos3, tbl.pos4, coltransparent)
    end

    render.SetStencilReferenceValue( 1 )
    render.SetStencilCompareFunction( STENCIL_EQUAL )
    render.SetStencilPassOperation( STENCIL_KEEP )
    render.SetStencilZFailOperation( STENCIL_INCR )
    render.SetStencilFailOperation( STENCIL_KEEP )

    for i = 1, #holes do
        local tbl = holes[i]

        if !tbl.dot then continue end
        local normf = tbl.hitnormal:Forward()
        local dot = tbl.dot
        --if dot < 0 then continue end
        local dot2 = tbl.dot2
        
        if dot > 0.5 and dot2 > 0.5 then
            render.DrawQuad(tbl.pos5, tbl.pos11, tbl.pos21, tbl.pos6, color_black)
            render.DrawQuad(tbl.pos8, tbl.pos41, tbl.pos11, tbl.pos5, color_black)
            render.DrawQuad(tbl.pos41, tbl.pos8, tbl.pos7, tbl.pos31, color_black)
            render.DrawQuad(tbl.pos31, tbl.pos7, tbl.pos6, tbl.pos21, color_black)
        else
            local mul = 0.1
            render.DrawQuad(tbl.pos1 - normf * mul, tbl.pos2 - normf * mul, tbl.pos3 - normf * mul, tbl.pos4 - normf * mul, color_black)
        end
    end

    render.SetStencilReferenceValue( 1 )
    render.SetStencilCompareFunction( STENCIL_EQUAL )

    render.SetStencilFailOperation( STENCIL_KEEP )
    
    render.DrawTextureToScreen(rt)
    
    --surface.SetTexture(rt)
    --surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

    render.SetStencilReferenceValue( 2 )
    render.SetStencilCompareFunction( STENCIL_EQUAL )

    render.ClearBuffersObeyStencil(10, 10, 10, 255, false)

    render.SetStencilEnable( false )
end)
