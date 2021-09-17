-- MIT License

-- Copyright (c) 2021 David Fletcher

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- helper methods
-- create an error alert and exit the dialog
local function create_error(str, dialog, exit)
    app.alert(str)
    if (exit == 1) then dialog:close() end
end

-- create a confirmation dialog and wait for the user to confirm
local function create_confirm(str)
    local confirm = Dialog("Confirm?")

    confirm:label {
        id="text",
        text=str
    }

    confirm:button {
        id="cancel",
        text="Cancel",
        onclick=function()
            confirm:close()
        end
    }

    confirm:button {
        id="confirm",
        text="Confirm",
        onclick=function()
            confirm:close()
        end
    }

    -- always give the user a way to exit
    local function cancelWizard(confirm)
        confirm:close()
    end

    -- show to grab centered coordinates
    confirm:show{ wait=true }

    return confirm.data.confirm
end

-- get an Image's Size
local function get_size(image)
    return Size(image.width, image.height)
end

-- mathematical functions
-- grow animation
local function grow_image_by(image, delta)
    -- get the current width and height as a Size object
    local size = get_size(image)

    -- resize and save back to the image
    size.width = size.width + delta
    size.height = size.height + delta

    image:resize{size=size, method="rotsprite", pivot=Point(image.width/2, image.height/2)}
end

-- shrink animation
local function shrink_image_by(image, delta)
    -- get the current width and height as a Size object
    local size = get_size(image)

    -- resize and save back to the image
    size.width = size.width - delta
    size.height = size.height - delta

    image:resize{size=size, method="rotsprite", pivot=Point(image.width/2, image.height/2)}
end

-- get linear delta
local function linear_delta(props, total_frames, current_frame, image)
    -- since this is linear, we can just do simple addition
    return (current_frame - props.start_frame) * (props.linear_delta_px)
end

-- get cubic delta
local function cubic_delta(props, total_frames, current_frame, image)
    local delta = 0
    local size = get_size(image)

    local time = ((current_frame - props.start_frame) / total_frames) * 2
    local width_delta = math.abs(props.cubic_intended_width - size.width)
    
    -- equations found from: https://www.gizma.com/easing/
    if (time < 1) then
        delta = (width_delta / 2) * (time ^ 3)
    else
        time = time - 2
        delta = (width_delta / 2) * ((time ^ 3) + 2)
    end
        
    return delta
end

-- dialog functions
-- open page1 again ("Previous" was clicked)
local function openPage1()
    -- close page2 and navigate back to page1
    page2:close()

    page1:show{ wait=true }
end

-- close page1 and open page2 with page1's properties
local function openPage2()
    -- grab and save page1's data
    local props = page1.data
    page1:close()

    -- choose which props to show or hide from page2 based on props
    if (props.ease_type == "Linear") then
        page2:modify {
            id="linear_delta_px",
            visible=true
        }

        page2:modify {
            id="cubic_intended_width",
            visible=false
        }
    else
        page2:modify {
            id="linear_delta_px",
            visible=false
        }

        page2:modify {
            id="cubic_intended_width",
            visible=true
        }
    end

    -- set the bounds
    page2.bounds = Rectangle(page1.bounds.x, page1.bounds.y, page2.bounds.width, page2.bounds.height)

    page2:show{ wait=true }
end

-- always give the user a way to exit
local function cancelWizard(dlg)
    dlg:close()
end

-- main brunt of the logic begins here
local function processAnimation()
    page2:close()

    -- merge dialog properties into one easy to use object
    local props = {}
    for k, v in pairs(page1.data) do
        props[k] = v
    end

    for k, v in pairs(page2.data) do
        props[k] = v
    end

    -- start a transaction so it can be "undone" quickly and easily
    app.transaction( function()
        -- initialize helper variables
        -- grab the references to the active objects
        local sprite = app.activeSprite
        local start_frame = props.start_frame
        local original_pos = app.activeCel.position
        local original_img = app.activeCel.image
        local original_layer = app.activeLayer

        -- grab frame information
        local end_frame = props.start_frame + props.dur_frames - 1

        -- get the transformation function we will be using
        local transform_func = function() end
        if (props.grow_shrink == "Shrink") then
            transform_func = shrink_image_by
        else
            transform_func = grow_image_by
        end

        -- get the scaling function we will be using
        local scale_func = function() end
        if (props.ease_type == "Linear") then
            scale_func = linear_delta
        else
            scale_func = cubic_delta
        end

        -- copy the non-animated layer data
        local copy_cels = {}
        for idx, layer in ipairs(sprite.layers) do
            local cel = layer:cel(start_frame)
            if (cel ~= nil) then
                copy_cels[idx] = {
                    image = cel.image,
                    pos = cel.position
                }
            end
        end

        -- set the active frame to start_frame
        for i=start_frame, end_frame do
            -- create a new frame
            app.activeFrame = sprite:newEmptyFrame(i)

            -- draw back all other layers as they were before
            for idx, layer in ipairs(sprite.layers) do
                if (copy_cels[idx] ~= nil) then
                    local paste_cel = sprite:newCel(layer, app.activeFrame, copy_cels[idx].image, copy_cels[idx].pos)
                end
            end

            -- populate a new (animated) cel with the original_img
            local cel = sprite:newCel(original_layer, app.activeFrame, original_img, original_pos)
            app.activeCel = cel

            -- commit the transform
            local delta = scale_func(props, props.dur_frames, i, original_img)
            transform_func(app.activeCel.image, delta)
        end

    end ) -- end transaction
end

-- validate properties
local function validate_properties()
    -- merge dialog properties into one easy to use object
    local props = {}
    for k, v in pairs(page1.data) do
        props[k] = v
    end

    for k, v in pairs(page2.data) do
        props[k] = v
    end

    -- validate fields
    if (props.start_frame == nil) or (props.start_frame < 1) then
        return "The starting frame must be 1 or higher."
    elseif (app.activeSprite.frames[props.start_frame] == nil) then
        return "The starting frame does not exist."
    end

    if (props.dur_frames == nil) or (props.dur_frames < 1) then
        return "The frame duration must be 1 or higher."
    end

    -- only validate against page2 props that were typed in
    if (props.ease_type == "Linear") then
        if (props.linear_delta_px < 1) then
            if not create_confirm("The change in pixels between each frame is currently negative or 0. Continue?") then
                return "User cancelled animation creation."
            end
        end
    end

    if (props.ease_type == "Cubic") then
        if props.cubic_intended_width < 0 then
            if not create_confirm("The target for the final sprite's width is negative. Continue?") then
                return "User cancelled animation creation."
            end
        end
    end

    -- script doesn't function if we don't have an active cel
    if (app.activeCel == nil) then
        return "The current cel has no pixel information. Aborting."
    end
end

--------------------------
-- declare page 1 object
--------------------------
page1 = Dialog("Shrink / Grow Sprite Animation (1/2)")

page1:separator {
    id="frame_fields",
    text="Frame Info"
}

page1:number {
    id="start_frame",
    label="Start animation on frame:",
    decimals=0
}

page1:number {
    id="dur_frames",
    label="For how many frames?",
    decimals=0
}

page1:separator {
    id="frame_fields",
    text="Animation Direction"
}

page1:combobox {
    id="grow_shrink",
    label="Should the animation shrink or grow?",
    option="Shrink",
    options={ "Shrink", "Grow" }
}

page1:combobox {
    id="ease_type",
    label="Animation rate of change:",
    option="Linear",
    options={ "Linear", "Cubic" }
}

page1:separator {
    id="footer"
}

page1:button {
    id="cancel",
    text="Cancel",
    onclick=function()
        cancelWizard(page1)
    end
}

page1:button {
    id="next",
    text="Next",
    onclick=function()
        openPage2()
    end
}

--------------------------
-- declare page 2 object
--------------------------
page2 = Dialog("Shrink / Grow Sprite Animation (2/2)")

page2:number {
    id="linear_delta_px",
    label="How much should each frame change in size (px)?",
    decimals=0
}

page2:number {
    id="cubic_intended_width",
    label="What is the WIDTH (in px) that you'd like the last frame to be?",
    decimals=0
}

page2:separator {
    id="footer"
}

page2:button {
    id="back",
    text="Back",
    onclick=function()
        openPage1()
    end
}

page2:button {
    id="ok",
    text="OK",
    onclick=function()
        local err = validate_properties()
        if (err ~= nil) then create_error(err, page2, 0) return end
        local confirmed = create_confirm("Animation will begin on frame "..page1.data.start_frame.."; using the image in the active cel. Continue?")
        if (confirmed) then processAnimation() end
    end
}

-- show to grab centered coordinates
page1:show{ wait=true }
