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

-- mathematical functions
-- grow animation
local function grow_image_by(image, delta)

end

-- shrink animation
local function shrink_image_by(image, delta)

end

-- get linear delta
local function linear_delta(props, total_frames, current_frame)

end

-- get cubic delta
local function cubic_delta(props, total_frames, current_frame)

end

-- dialog functions
-- open page1 again ("Previous" was clicked)
local function openPage1(page2)
    -- close page2 and navigate back to page1
    page2:close()

    page1:show{ wait=true }
end

-- close page1 and open page2 with page1's properties
local function openPage2(page1)
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
            id="max_delta_px",
            visible=false
        }

        page2:modify {
            id="ease_frames",
            visible=false
        }
    else
        page2:modify {
            id="linear_delta_px",
            visible=false
        }

        page2:modify {
            id="max_delta_px",
            visible=true
        }
        
        page2:modify {
            id="ease_frames",
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
local function processAnimation(page2)
    page2:close()

    -- merge dialog properties into one easy to use object
    local props = {}
    for k, v in pairs(page1.data) do
        props[k] = v
    end

    for k, v in pairs(page2.data) do
        props[k] = v
    end

    -- initialize helper variables
    -- grab the active cel's image
    local original_img = app.activeImage

    -- grab frame information
    local start_frame = props.start_frame
    local end_frame = props.start_frame + props.dur_frames

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

    -- loop from start_frame to end_frame and animate accordingly
    for i=start_frame, end_frame do

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
        openPage2(page1)
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
    id="max_delta_px",
    label="What is the max each frame should change in size (px)?",
    decimals=0
}

page2:number {
    id="ease_frames",
    label="How many frames to ease the animation?",
    decimals=0
}

page2:separator {
    id="footer"
}

page2:button {
    id="back",
    text="Back",
    onclick=function()
        openPage1(page2)
    end
}

page2:button {
    id="ok",
    text="OK",
    onclick=function()
        local confirmed = create_confirm("Animation will begin on frame X; using the image in the active cel. Continue?")
        if (confirmed) then processAnimation(page2) end
    end
}

-- show to grab centered coordinates
page1:show{ wait=true }
