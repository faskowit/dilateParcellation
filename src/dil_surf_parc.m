function [ dil_vert_weights , no_more_to_dil ] = dil_surf_parc(vert_weights,nbrs,gap_wei,nbrs_size)
% dilate a parcellation on the surface - a simple way to dilate a
% collection of labels on a freesurfer surface so as to fill in surface
% gaps. for unlabeled vertices of label borders, this function assigns a
% value based on the mode of neighbor weights that its connected to; using
% the nbrs_size var, you can modulate the topological 'distance' of the
% neighborhood to read from.
%
% INPUTS
%
% vert_weights:         vector (length == number of verticies) of label
%                       weights
% nbrs:                 matrix (size1 == number of verticies) of neighbors
%                       per vertex
% gap_wei:              the weight in the vert_weight that corresponds to
%                       gap to be filled; default=1
% nbrs_size:            when computing the neighbooring label weights, how
%                       many steps away to read. 1 or 2 seem to work well;
%                       default=1
%
% OUTPUTS
%
% dil_vert_weights      the dilated weights
% no_more_to_dil        a boolean that returns 0, unless there are no more
%                       weights that equal the gap_wei val (if this is the
%                       case, then there are no more gaps to dilate into)
%
% Josh Faskowitz
% Indiana University
% Computational Cognitive Neurosciene Lab
% See LICENSE file for license
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do a little input checking

if ~exist('gap_wei','var') || isempty(gap_wei)
    gap_wei = 1 ;
end

if ~exist('nbrs_size','var') || isempty(nbrs_size)
    % most local
    nbrs_size = 1 ;
end

if nbrs_size < 1
   error('invalid nbrs_size') 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize seed for potential random numbers
rng(4321)

% conditional that will return 1 only when no more vertices to dilate
no_more_to_dil = 0 ;

% copy weights_to_dilate
dil_vert_weights = vert_weights .* 1 ;

% indicides for all verts, number of verticies should just be height of the
% neighbors matrix
all_verts_ind = 1:(size(nbrs,1));

% get a list of all verticies with gap label
fill_verts = all_verts_ind(vert_weights == gap_wei)';

% get rid of any possible zero neighbors
nbrs(nbrs==0) = -1 ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first loop to find verts to fill, 
% we want verts that border a label area

bord_fill_verts = zeros(size(fill_verts,1),1) ;

for idx = 1:size(fill_verts,1)

    vert_to_fill = fill_verts(idx) ;
    fill_nbrs = nbrs(vert_to_fill,:) ;
    % trim any of the potential -1
    fill_nbrs = fill_nbrs(fill_nbrs > 0) ;
    fill_nbrs_vals = vert_weights(fill_nbrs) ; 
    
    % if this vert touches label
    if sum(fill_nbrs_vals~=gap_wei) > 0
        bord_fill_verts(idx) = 1 ;
    end
end

% the verts we actuall want to dilate into
bord_fill_verts = fill_verts(~~bord_fill_verts) ;

if isempty(bord_fill_verts)
    disp('no more verticies to fill')
    no_more_to_dil = 1 ;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop through the bord_fill_verts

for idx = 1:size(bord_fill_verts,1)
        
    % vert of current interest
    vert_to_fill = bord_fill_verts(idx) ;
            
    % get neighboors
    fill_nbrs = nbrs(vert_to_fill,:) ;
    
    % trim any of the potential -1
    fill_nbrs = fill_nbrs(fill_nbrs > 0) ;
        
    % copy for potential neigborhood loop
    get_nbrs = vert_to_fill .* 1;
            
    for jdx = 1:nbrs_size
                
        fill_nbrs = nbrs(get_nbrs,:) ;
        % trim any of the potential -1
        % this also unrolls into vector, which we want anyways
        fill_nbrs = fill_nbrs(fill_nbrs > 0) ;
        
        get_nbrs = fill_nbrs ;
    end
    
    fill_nbrs_vals = vert_weights(fill_nbrs) ; 
    fill_nbrs_vals = fill_nbrs_vals(fill_nbrs_vals~=gap_wei) ;
    % find the consensus
    [~,~,vert_fill_val] = mode(fill_nbrs_vals) ;

    % will happen if empty vec given to mode... shouldn't happen in this
    % loop but kept in for good measure
    
    if size(vert_fill_val{1},1) == 1
        % if only one mode

        vert_fill_val = vert_fill_val{1} ;
        
        if isempty(vert_fill_val)
            vert_fill_val = gap_wei ;
        end
    else
        % if more than one mode, choose randomly which to assign; to ensure
        % consistent performance rng seed set at the beginnign
        rand_ind = randi(size(vert_fill_val{1},1)) ;        
        vert_fill_val = vert_fill_val{1}(rand_ind);
    end
      
    dil_vert_weights(vert_to_fill) = vert_fill_val ;
end
