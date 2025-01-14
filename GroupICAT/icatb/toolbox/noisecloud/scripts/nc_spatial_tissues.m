function feature = nc_spatial_tissues(spatialMap, threshold);
          global gm_map wm_map csf_map edges_map midbrain_map eyeballs_map skull_map cerebellum_map ventricles_map cord_map;

    % salman 20200602
    % without thresholding every SM returns the same tissue features
    if ~isnan(threshold)
        spatialMap( abs( spatialMap(:) ) < threshold ) = 0;
    end

          % Labels are;
      % perc_activation_wm,perc_activation_gray,perc_activation_csf,perc_activation_eyeballs,perc_activation_mni152edges,perc_activation_midbrain,perc_activation_skull,perc_activation_ventricles,perc_activation_cerebellum,perc_activation_spinalcord,;
      % PROPORTION VOXELS IN TISSUE TYPES;
     % Requires tissue type images registered to spatialMap space, see;
     % INSTRUCTIONS.txt for details;
      % VOXELS IN MATTER TYPES;
     % Each map for gm,wm,csf, has a probability from 0 to 1 of the matter;
     % type.  If we use a binary mask of the network and multiply by this;
     % probability map and sum the probabilities, we get a summed liklihood.;
     % We can then divide by the total voxels of activation to get a;
      % percentage of total voxels that belong to that matter type.;
      % First calculate total number voxels of activation;
     total_activation_voxels = sum(spatialMap(:) ~= 0);
      % Feature 10/127: Percentage total activation in white matter;
     feature(1) = sum((spatialMap(:) ~= 0) .* wm_map(:)) / total_activation_voxels;
      % Feature 11/128: Percentage total activation in gray matter;
     feature(2) = sum((spatialMap(:) ~= 0) .* gm_map(:)) / total_activation_voxels;
      % Feature 12/129: Percentage total activation in csf;
     feature(3) = sum((spatialMap(:) ~= 0) .* csf_map(:)) / total_activation_voxels;
      % Feature 13/130: Percentage total activation in eyeballs;
     feature(4) = sum((spatialMap(:) ~= 0) .* eyeballs_map(:)) / total_activation_voxels;
      % Feature 14/131: Percentage total activation in all MNI152 "edges";
     feature(5) = sum((spatialMap(:) ~= 0) .* edges_map(:)) / total_activation_voxels;
      % Feature 15/132: Percentage total activation in midbrain;
     feature(6) = sum((spatialMap(:) ~= 0) .* midbrain_map(:)) / total_activation_voxels;
      % Feature 16/133: Percentage total activation in skull;
     feature(7) = sum((spatialMap(:) ~= 0) .* skull_map(:)) / total_activation_voxels;
      % Feature 17/134: Percentage total activation in ventricles;
     feature(8) = sum((spatialMap(:) ~= 0) .* ventricles_map(:)) / total_activation_voxels;
      % Feature 18/135: Percentage total activation in cerebellum;
     feature(9) = sum((spatialMap(:) ~= 0) .* cerebellum_map(:)) / total_activation_voxels;
      % Feature 19/136: Percentage total activation in spinal cord;
     feature(10) = sum((spatialMap(:) ~= 0) .* cord_map(:)) / total_activation_voxels;
  end