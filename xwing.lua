-- X-Wing Automatic Movement - Hera Verito (Jstek), March 2016
-- X-Wing Arch and Range Ruler - Flolania, March 2016
-- X-Wing Auto Dial Integration - Flolania, March 2016

function onload()
--Auto Movement
  undolist = {}
  undopos = {}
  undorot = {}
  namelist1 = {}
  locktimer = {}

 --Auto Dials
 --dial information
  dialpositions = {}

--Auto Bumping
  BumpingData = {}

-- Auto Actions
  focus = 'beca0f'
  evade = '4a352e'
  stress = 'a25e12'
end

function PlayerCheck(Color, GUID)
    local PC = false
    if getPlayer(Color) ~= nil then
        HandPos = getPlayer(Color).getPointerPosition()
        DialPos = getObjectFromGUID(GUID).getPosition()
        if distance(HandPos['x'],HandPos['z'],DialPos['x'],DialPos['z']) < 2 then
            PC = true
        end
    end
    return PC
end

function onObjectLeaveScriptingZone(zone, object)
    if object.tag == 'Card' and object.getDescription() ~= '' then
        CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            obj = getObjectFromGUID(CardData["ShipGUID"])
            if obj.getVar('HasDial') == true then
    		    printToColor(CardData["ShipName"] .. ' already has a dial.', object.held_by_color, {0, 0, 1})
            else
                obj.setVar('HasDial', true)
                CardData["Color"] = object.held_by_color

                local flipbutton = {['click_function'] = 'CardFlipButton', ['label'] = 'Flip', ['position'] = {0, -1, 1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
        		object.createButton(flipbutton)
                local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {0, -1, -1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(deletebutton)

                object.setVar('Lock',true)
            end
    	else
            printToColor('That dial was not saved.', object.held_by_color, {0, 0, 1})
        end
    end
end

function CardInArray(GUID)
    CIAPos = nil
    for i, card in ipairs(dialpositions) do
        if GUID == card["GUID"] then
            CIAPos = i
        end
    end
    return CIAPos
end

function CardFlipButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        rot = getObjectFromGUID(CardData["ShipGUID"]).getRotation()
        object.setRotation({0,rot[2],0})
        object.clearButtons()
        local movebutton = {['click_function'] = 'CardMoveButton', ['label'] = 'Move', ['position'] = {0, 1, '.9'}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
        object.createButton(movebutton)
    end
end


function CardMoveButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],object.getDescription())
        object.clearButtons()

        local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {'-.35', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 650, ['font_size'] = 250}
        object.createButton(deletebutton)

        local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'q', ['position'] = {'-.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(undobutton)

        local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {'.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(focusbutton)

        local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {'.9', 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(stressbutton)

        local evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {'.9', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(evadebutton)

    end
end

function CardFocusButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(focus, CardData["ShipGUID"],-0.5,1,-0.5)
        notify(CardData["ShipGUID"],'action','takes a focus token')
    end
end

function CardStressButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(stress, CardData["ShipGUID"],0.5,1,0.5)
        notify(CardData["ShipGUID"],'action','takes stress')
    end
end

function CardEvadeButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(evade, CardData["ShipGUID"],-0.5,1,0.5)
        notify(CardData["ShipGUID"],'action','takes an evade token')
    end
end

function CardUndoButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],'undo')
        object.removeButton(1)
    end
end

function CardDeleteButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        getObjectFromGUID(CardData["ShipGUID"]).setVar('HasDial',false)
        object.Unlock()
        object.clearButtons()
        object.setPosition (CardData["Position"])
        object.setRotation (CardData["Rotation"])
        CardData["Color"] = nil
    end
end

function resetdials(guid,notice)
    obj = getObjectFromGUID(guid)
    local index = {}
    for i, card in ipairs(dialpositions) do
        if guid == card["ShipGUID"] then
            index[#index + 1] = i
        end
    end
    obj.setVar('HasDial',false)
    if notice == 1 then
        printToAll(#index .. ' dials removed for ' .. obj.getName() .. '.', {0, 0, 1})
    end
    for i=#index,1,-1 do
        table.remove(dialpositions, index[i])
    end
    setpending(guid)
end

function checkdials(guid)
    resetdials(guid,0)
    obj = getObjectFromGUID(guid)
    count = 0
    display = false
    error = false
    deckerror = false
    for i,card in ipairs(getAllObjects()) do
        cardpos = card.getPosition()
        objpos = obj.getPosition()
        if distance(cardpos[1],cardpos[3],objpos[1],objpos[3]) < 5.5 then
            if cardpos[3] >= 18 or cardpos[3] <= -18 then
                if card.tag == 'Card' and card.getDescription() ~= '' then
                    CardData = dialpositions[CardInArray(card.getGUID())]
                    if CardData == nil then
                        count = count + 1
                        cardtable = {}
                        cardtable["GUID"] = card.getGUID()
                        cardtable["Position"] = card.getPosition()
                        cardtable["Rotation"] = card.getRotation()
                        cardtable["ShipGUID"] = obj.getGUID()
                        cardtable["ShipName"] = obj.getName()
                        cardtable["Color"] = nil
                        obj.setVar('HasDial',false)
                        dialpositions[#dialpositions +1] = cardtable
                        card.setName(obj.getName())
                    else
                        display = true
                    end
                end
                if card.tag == 'Deck' then
                    deckerror = true
                end
            else
                error = true
            end
        end
    end
    if display == true then
        printToAll('Error: ' .. obj.getName() .. ' attempted to save dials already saved to another ship. Use rd on old ship first.',{0, 0, 1})
    end
    if deckerror == true then
        printToAll('Error: Cannot save dials in deck format.',{0, 0, 1})
    end
    if error == true then
        printToAll('Caution: Cannot save dials in main play area.',{0, 0, 1})
    end
    if count <= 17 then
        printToAll(count .. ' dials saved for ' .. obj.getName() .. '.', {0, 0, 1})
    else
        resetdials(guid,0)
        printToAll('Error: Tried to save to many dials for ' .. obj.getName() .. '.', {0, 0, 1})
    end
    setpending(guid)
end

function distance(x,y,a,b)
    x = (x-a)*(x-a)
    y = (y-b)*(y-b)
    return math.sqrt(math.abs((x+y)))
end

function SpawnDialGuide(guid)
  shipobject = getObjectFromGUID(guid)
  world = shipobject.getPosition()
  direction = shipobject.getRotation()
  obj_parameters = {}
  obj_parameters.type = 'Custom_Model'
  obj_parameters.position = {world[1], world[2]+0.15, world[3]}
  obj_parameters.rotation = { 0, direction[2], 0 }
  DialGuide = spawnObject(obj_parameters)
  custom = {}
  custom.mesh = 'http://pastebin.com/raw/qPcTJZyP'
  custom.collider = 'http://pastebin.com/raw.php?i=UK3Urmw1'

  DialGuide.setCustomObject(custom)
  DialGuide.lock()
  DialGuide.scale({'.4','.4','.4'})

  local button = {['click_function'] = 'GuideButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 270, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 500}
  DialGuide.createButton(button)
  shipobject.setDescription('Pending')
  checkdials(guid)
end

function GuideButton(object)
  object.destruct()
end

function update ()
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' then
           shipguid = ship.getGUID()
           shipname = ship.getName()
           shipdesc = ship.getDescription()
           checkname(shipguid,shipdesc,shipname)
           check(shipguid,shipdesc)
        end
        if ship.getVar('Lock') == true and ship.held_by_color == nil and ship.resting == true then
            ship.setVar('Lock',false)
            ship.lock()
        end
    end


end

function round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function take(parent, guid, xoff, yoff, zoff)
  obj = getObjectFromGUID(guid)
  objp = getObjectFromGUID(parent)
  world = obj.getPosition()
  local params = {}
  params.position = {world[1]+xoff, world[2]+yoff, world[3]+zoff}
  objp.takeObject(params)
end

function undo(guid)
 if undolist[guid] ~= nil then
  obj = getObjectFromGUID(guid)
  obj.setPosition(undopos[guid])
  obj.setRotation(undorot[guid])
  setpending(guid)
 else
  obj = getObjectFromGUID(guid)
  setpending(guid)
 end
 obj.Unlock()
end

function storeundo(guid)
 obj = getObjectFromGUID(guid)
 direction = obj.getRotation()
 world = obj.getPosition()
 undolist[guid] = guid
 undopos[guid] = world
 undorot[guid] = direction
end

function registername(guid)
  obj = getObjectFromGUID(guid)
  name = obj.getName()
  namelist1[guid] = name
  setlock(guid)
end

function checkname(guid,move,name)
 if move == 'Pending' then
  if namelist1[guid] == nil then
   namelist1[guid] = name
  end
 end
end

function fixname(guid)
 if namelist1[guid] ~= nil then
  obj = getObjectFromGUID(guid)
  obj.setName(namelist1[guid])
 end
end

function setpending(guid)
 fixname(guid)
 obj = getObjectFromGUID(guid)
 obj.setDescription('Pending')
end

function setlock(guid)
 fixname(guid)
 obj = getObjectFromGUID(guid)
 obj.setDescription('Locking')
end


function notify(guid,move,text)
 if text == nil then
  text = ''
 end

 obj = getObjectFromGUID(guid)
 name = obj.getName()
 if move == 'q' then
  printToAll(name .. ' executed undo.', {0, 1, 0})
 elseif move == 'set' then
  printToAll(name .. ' set name.', {0, 1, 1})
 elseif move == 'r' then
  printToAll(name .. ' spawned a ruler.', {0, 0, 1})
  elseif move == 'action' then
  printToAll(name .. ' ' .. text .. '.', {0.959999978542328 , 0.439000010490417 , 0.806999981403351})
  else
  printToAll(name .. ' ' .. text ..' (' .. move .. ').', {1, 0, 0})
 end
end


function check(guid,move)
-- Checking for Lock
if move == 'Locking' then
 if locktimer[guid] ~= nil or locktimer[guid] == 0 then
   if locktimer[guid] > 1 then
     locktimer[guid] = locktimer[guid] - 1
   elseif locktimer[guid] == 0 then
     locktimer[guid] = 100
   else
     locktimer[guid] = 0
     obj = getObjectFromGUID(guid)
     obj.lock()
     setpending(guid)
   end
 else
   locktimer[guid] = 100
 end
end

--Ruler
 if move == 'r' or move == 'ruler' then
--     obj = getObjectFromGUID(guid)
--     direction = obj.getRotation()
--     world = obj.getPosition()
--     getCorners(world[1],world[3],direction[2])
--     getCorners2(guid)

GetPerpDistance('7f0ac1','704cad')

     setpending(guid)
 end

--DialCheck
 if move == 'sd' or move == 'storedial' or move == 'storedials' then
  if move == 'sd' then
    checkdials(guid)
  else
    SpawnDialGuide(guid)
  end
 end
 if move == 'rd' or move == 'removedial' or move == 'removedials' then
  resetdials(guid, 1)
 end


-- Straight Commands
 if move == 's0' then
     obj = getObjectFromGUID(guid)
     obj.setPosition( {0,2,0} )
     obj.setRotation({0,0,0})
     setpending(guid)





 end
 if move == 's1' then
  straight(guid,2.5,1.45)
  notify(guid,move,'flew straight 1')
 elseif move == 's2' or move == 'cs' then
  if move == 's2' then
   straight(guid,4.35,1.45)
   notify(guid,move,'flew straight 2')
  else
   if shipname:match '%LGS$' then
   else
     straight(guid,4.35,1.45)
     notify(guid,move,'decloaked straight 2')
   end
  end
 elseif move == 's3' then
  straight(guid,5.79,1.45)
  notify(guid,move,'flew straight 3')
 elseif move == 's4' then
  straight(guid,7.25,1.5)
  notify(guid,move,'flew straight 4')
 elseif move == 's5' then
  straight(guid,8.68,1.45)
  notify(guid,move,'flew straight 5')
-- Bank Commands
 elseif move == 'br1' then
  right(guid,3.33,1.36,45,1.26,0.5)
  notify(guid,move,'banked right 1')
 elseif move == 'br2' then
  right(guid,4.59,1.89,45,1.26,0.5)
  notify(guid,move,'banked right 2')
 elseif move == 'br3' then
  right(guid,5.91032266616821,2.5119037628174,45,1.26,0.5)
  notify(guid,move,'banked right 3')
 elseif move == 'bl1' or move == 'be1' then
  left(guid,3.33,1.36,-45,1.26,0.5)
  notify(guid,move,'banked left 1')
 elseif move == 'bl2' or move == 'be2' then
  left(guid,4.59,1.89,-45,1.26,0.5)
  notify(guid,move,'banked left 2')
 elseif move == 'bl3' or move == 'be3' then
  left(guid,5.91032266616821,2.5119037628174,-45,1.26,0.5)
  notify(guid,move,'banked left 3')
-- Turn Commands
 elseif move == 'tr1' then
  right(guid,1.9999457550049,2.00932357788086,90,0.7,0.75)
  notify(guid,move,'turned right 1')
 elseif move == 'tr2' then
  right(guid,2.9963474273682,2.97769641876221,90,0.7,0.75)
  notify(guid,move,'turned right 2')
 elseif move == 'tr3' then
  right(guid,3.9047927856445,4.052940441535946,90,0.7,0.75)
  notify(guid,move,'turned right 3')
 elseif move == 'tl1' or move == 'te1' then
  left(guid,2.0049457550049,2.02932357788086,270,0.7,0.75)
  notify(guid,move,'turned left 1')
 elseif move == 'tl2' or move == 'te2' then
  left(guid,2.9963474273682,2.97769641876221,270,0.7,0.75)
  notify(guid,move,'turned left 2')
 elseif move == 'tl3' or move == 'te3' then
  left(guid,3.9047927856445,4.052940441535946,270,0.7,0.75)
  notify(guid,move,'turned left 3')
-- Koiogran Turn Commands
 elseif move == 'k2' then
  straightk(guid,4.35,1.45)
  notify(guid,move,'koiogran turned 2')
 elseif move == 'k3' then
  straightk(guid,5.79,1.45)
  notify(guid,move,'koiogran turned 3')
 elseif move == 'k4' then
  straightk(guid,7.25,1.45)
  notify(guid,move,'koiogran turned 4')
 elseif move == 'k5' then
  straightk(guid,8.68,1.45)
  notify(guid,move,'koiogran turned 5')
-- Segnor's Loop Commands
 elseif move == 'bl2s' or move == 'be2s' then
  left(guid,4.59,1.89,135,1.26,0.5)
  notify(guid,move,'segnors looped left 2')
 elseif move == 'bl3s' or move == 'be3s' then
  left(guid,5.91032266616821,2.5119037628174,135,1.26,0.5)
  notify(guid,move,'segnors looped left 3')
 elseif move == 'br2s' then
  right(guid,4.59,1.89,225,1.26,0.5)
  notify(guid,move,'segnors looped right 2')
 elseif move == 'br3s' then
  right(guid,5.91032266616821,2.5119037628174,225,1.26,0.5)
  notify(guid,move,'segnors looped right 3')
-- Barrel Roll Commands
 elseif move == 'xl' or move == 'xe' then
  if shipname:match '%LGS$' then
    left(guid,0,0.73999404907227,0,0,2.87479209899903)
  else
    left(guid,0,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled left')
 elseif move == 'xlf' or move == 'xef' or move == 'rolllf' or move == 'rollet' then
  if shipname:match '%LGS$' then
    left(guid,2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
  else
    left(guid,0.73999404907227,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled forward left')
 elseif move == 'xlb' or move == 'xeb' or move == 'rolllb'  or move == 'rolleb' then
  if shipname:match '%LGS$' then
    left(guid,-2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
  else
    left(guid,-0.73999404907227,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled backwards left')
 elseif move == 'xr' or move == 'rollr'then
  if shipname:match '%LGS$' then
    right(guid,0,0.73999404907227,0,0,2.87479209899903)
  else
    right(guid,0,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled right')
 elseif move == 'xrf' or move == 'rollrf' then
  if shipname:match '%LGS$' then
    right(guid,2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
  else
    right(guid,0.73999404907227,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled forward right')
 elseif move == 'xrb' or move == 'rollrb' then
  if shipname:match '%LGS$' then
    right(guid,-2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
  else
    right(guid,-0.73999404907227,2.8863945007324,0,0,0)
  end
  notify(guid,move,'barrel rolled backwards right')
-- Decloak Commands
 elseif move == 'cl' or move == 'ce' then
  if shipname:match '%LGS$' then
  else
    left(guid,0,4.3295917510986,0,0,0)
    notify(guid,move,'decloaked left')
  end
 elseif move == 'clf' or move == 'cef' then
  if shipname:match '%LGS$' then
  else
    left(guid,0.73999404907227,4.3295917510986,0,0,0)
    notify(guid,move,'decloaked forward left')
  end
 elseif move == 'clb' or move == 'ceb' then
  if shipname:match '%LGS$' then
  else
    left(guid,-0.73999404907227,4.3295917510986,0,0,0)
    notify(guid,move,'decloaked backwards left')
  end
 elseif move == 'cr' or move == 'ce' then
  if shipname:match '%LGS$' then
  else
    right(guid,0,4.3295917510986,0,0,0)
    notify(guid,move,'decloaked right')
  end
 elseif move == 'crf' then
  if shipname:match '%LGS$' then
  else
    right(guid,0.73999404907227,4.3295917510986,0,0,0)
    notify(guid,move,'decloaked forward right')
  end
 elseif move == 'crb' then
  if shipname:match '%LGS$' then
  else
    right(guid,-0.73999404907227,4.3295917510986,0,0,0)
    notify(guid,move,'decloak backwards right')
  end
-- MISC Commands
 elseif move == 'checkpos' then
  checkpos(guid)
 elseif move == 'checkrot' then
  checkrot(guid)
 elseif move == 'keep' then
  storeundo(guid)
  setpending(guid)
 elseif move == 'set' then
  registername(guid)
  notify(guid,move)
 elseif move == 'undo' or move == 'q' then
  undo(guid)
  notify(guid,'q')
 end
end

function checkpos(guid)
 setpending(guid)
 obj = getObjectFromGUID(guid)
 world = obj.getPosition()
 for i, v in ipairs(world) do
 print(v)
 end
end

function checkrot(guid)
 setpending(guid)
 obj = getObjectFromGUID(guid)
 world = obj.getRotation()
 for i, v in ipairs(world) do
 print(v)
 end
end

function ruler(guid)

  shipobject = getObjectFromGUID(guid)
  shipname = shipobject.getName()
  direction = shipobject.getRotation()
  world = shipobject.getPosition()
  scale = shipobject.getScale()

  obj_parameters = {}
  obj_parameters.type = 'Custom_Model'
  obj_parameters.position = {world[1], world[2]+0.28, world[3]}
  obj_parameters.rotation = { 0, direction[2] +180, 0 }
  newruler = spawnObject(obj_parameters)
  custom = {}
  if shipname:match '%LGS$' then
    custom.mesh = 'http://pastebin.com/raw/3AU6BBjZ'
    custom.collider = 'https://paste.ee/r/JavTd'
  else
    custom.mesh = 'http://pastebin.com/raw/wkfqqnwX'
    custom.collider = 'https://paste.ee/r/6jn13'
  end
  newruler.setCustomObject(custom)
  newruler.lock()
  newruler.scale(scale)
  setpending(guid)
  local button = {['click_function'] = 'actionButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 500}
  newruler.createButton(button)
  notify(guid,'r')
end

function actionButton(object)
  object.destruct()
end