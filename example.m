clc 
clearvars

%% add current directory

addpath(genpath(pwd))

%% read in some data

% inf_surf_lh = './example_data/lh.inflated' ;
inf_surf_rh = './example_data/rh.inflated' ;

% annot_lh = './example_data/lh.YeoUpsample.annot' ;
annot_rh = './example_data/rh.YeoUpsample.annot' ;

[~,annotLabs,annotTable] = read_annotation(annot_rh) ;
[verts,faces] = read_surf(inf_surf_rh);

%% get the neigbors 

s = struct() ;
s.nverts = size(verts,1) ;
s.nfaces = size(faces,1) ;
s.faces = faces + 1 ;
s.coords = verts ;

n = fs_find_neighbors(s) ;

%% load the annotation file

w = ones(length(annotLabs),1);
for idx = 1:size(annotTable.table,1)
    disp(idx)
    w(annotLabs == annotTable.table(idx,5)) = idx;
end

%% viz the labels pre-dilation

figure
colormap(annotTable.table(:,1:3) ./ 255)

RH = trisurf(s.faces,...
    s.coords(:,1),...
    s.coords(:,2),...
    s.coords(:,3),...
    w);
set(RH,'EdgeColor','none');
axis equal; axis off
view(90,0)
camlight headlight; material dull; lighting gouraud
RH.CDataMapping = 'direct' ;

%% dilate surface based on neighbors

% function [ dil_vert_weights ] = dil_surf_parc(vert_weights,nbrs,gap_wei,nbrs_size)
w_dil = dil_surf_parc(w,n.nbrs,1,2) ;

fin = 0 ;
idx = 1 ;
while ~fin
    disp(idx)
    idx = idx + 1;
    [w_dil,fin] = dil_surf_parc(w_dil,n.nbrs,1,2) ;
end

%% viz the labels after dilation 

figure
colormap(annotTable.table(:,1:3) ./ 255)

RH = trisurf(s.faces,...
    s.coords(:,1),...
    s.coords(:,2),...
    s.coords(:,3),...
    w_dil);
set(RH,'EdgeColor','none');
axis equal; axis off
view(90,0)
camlight headlight; material dull; lighting gouraud
RH.CDataMapping = 'direct' ;

%% dil only a couple of times

% function [ dil_vert_weights ] = dil_surf_parc(vert_weights,nbrs,gap_wei,nbrs_size)
w_dil_less = dil_surf_parc(w,n.nbrs,1,2) ;
w_dil_less = dil_surf_parc(w_dil_less,n.nbrs,1,2) ;

figure
colormap(annotTable.table(:,1:3) ./ 255)

RH = trisurf(s.faces,...
    s.coords(:,1),...
    s.coords(:,2),...
    s.coords(:,3),...
    w_dil_less);
set(RH,'EdgeColor','none');
axis equal; axis off
view(90,0)
camlight headlight; material dull; lighting gouraud
RH.CDataMapping = 'direct' ;
