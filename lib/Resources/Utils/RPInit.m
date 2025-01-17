function RPInit()
% RP Environment Initalization script
% This script initalizes sensors and creates the necessary information for
% all sensors to operate accordingly.
%  Copyright 2018 The MathWorks, Inc.

model=gcs;
environments=0;
isMlRobot=0;

set_param(model,'SimMechanicsRigidlyBoundBlock','none');
set_param(model,'UnconnectedLineMsg','none');

%%
envBlk=find_system(model,'MaskType','RP MATLAB Environment');

if size(envBlk)==1
    environments=environments+1;
    isMlRobot=1;
    block=envBlk{1};
    % Disable link so that the changes can be saved with the model
    set_param(block,'LinkStatus','breakWithoutHierarchy');
    set_param([block '/Robot'],'LinkStatus','breakWithoutHierarchy');
end

envBlk=find_system(model,'MaskType','RP Robot Motor');

if isempty(envBlk) && isMlRobot == 0
   error('No RP Motor blocks found. Please place necessary actuators to interact with the robot.') 
end

envBlk=find_system(model,'MaskType','RP Obstacle Environment');

if size(envBlk)==1
    environments=environments+1;
    block=envBlk{1};
    % Disable link so that the changes can be saved with the model
    set_param(block,'LinkStatus','breakWithoutHierarchy');
    
    Arena.length=eval(get_param(block,'arenaLength'));
    Arena.width=eval(get_param(block,'arenaWidth'));
    
    obstacles=eval(get_param(block,'obstacles'));
    
    create_and_delete_blocks(obstacles,block) % update obstacles 
    
    for idx=1:size(obstacles,1)
        Arena.obj(idx).recPose=obstacles(idx,:);
        
        pos=obstacles(idx,[1,2]);
        length=obstacles(idx,3);
        width=obstacles(idx,4);
    
        Arena.obj(idx).status='on';
        Arena.obj(idx).position=pos + [length,width]/2;
        Arena.obj(idx).length=length;
        Arena.obj(idx).width=width;
        
    end
    mapForSim=PlaygroundCreateSimMap(Arena,block);
    ws=get_param(model,'modelworkspace');
    
    try
        ws.assignin('mapForSim',mapForSim);
        ws.assignin('occGrid',mapForSim.simMap);
    catch
        disp('Make sure library block is placed in model')
    end
    
    
end

%%

envBlk=find_system(model,'MaskType','RP Object Environment');

if size(envBlk)==1
    environments=environments+1;
    block=envBlk{1};
    % Disable link so that the changes can be saved with the model
    set_param(block,'LinkStatus','breakWithoutHierarchy');
    
    Arena.width=eval(get_param(block,'arenaWidth'));
    Arena.length=eval(get_param(block,'arenaLength'));
    arenaDimensions=[Arena.width Arena.length];
    % Normalize the arena dimensions
    normDims=arenaDimensions/max(arenaDimensions);
    mapScale=2048/max(arenaDimensions);
    mapGridSize=round(normDims*2048);
    
    % Initialize obstacle map
    locObsMap = ones(mapGridSize(1),mapGridSize(2),'single');
    % add walls to occupancy map
    locObsMap(1:5,:)=0;
    locObsMap(end-5:end,:)=0;
    locObsMap(:,1:5)=0;
    locObsMap(:,end-5:end)=0;
    
    mapForSim.obsMap=locObsMap;
    mapForSim.scaleFactor=mapScale;
    % Create simulation map using binary occupancy grid
    % compMap = imcomplement(locObsMap); %binary occupancy grid flips this for some reason
    compMap=1-locObsMap;
    mapForSim.simMap = robotics.BinaryOccupancyGrid(compMap,mapScale);

    ws=get_param(gcs,'modelworkspace');
    
    try
        ws.assignin('mapForSim',mapForSim);
        ws.assignin('occGrid',mapForSim.simMap);
    catch
        disp('Make sure library block is placed in model')
    end
    
end


%%
envBlk=find_system(model,'MaskType','RP Sumo Game');

if size(envBlk)==1
    environments=environments+1;
    block=envBlk{1};
    % Disable link so that the changes can be saved with the model
    set_param(block,'LinkStatus','breakWithoutHierarchy');
end
%%
if environments ~= 1
    if environments ==0
        error('Please ensure there is at least one environment block in your model')
    else
        error('Please ensure there is only one environment block in your model')
    end
end
end
