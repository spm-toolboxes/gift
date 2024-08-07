function feature = nc_temporal_bins(T)
      global TR;
          % TR should already be defined in the workspace;
     % Labels:;
     % power_band_0-0.008_Hz,power_band_0.02-0.05_Hz,power_band_0.05-0.1_Hz,power_band_0.1-0.25_Hz;
      %--------------------------------------------------------------------------;
     % FEATURES 10-15: FREQUENCY BINS;
     % .01 to .1 Hz is "range of haemodynamic responses detectable with BOLD     % fMRI. "low" is 0 to .005 (what is our bandpass at?) (Tohnka);
     % Bins used by de Martino include:;
     % Power in band 0-0.008 Hz;
     % Power in band 0.008-0.02 Hz;
     % Power in band 0.02-0.05 Hz;
     % Power in band 0.05-0.1 Hz;
     % Power in band 0.1-0.25 Hz;
      % My current feature bands include:;
     % FEATURE 10 Power in band 0-0.008 Hz;
     % FEATURE 11 Power in band 0.008-0.02 Hz;
     % FEATURE 12: Power in band 0.02-0.05 Hz;
     % FEATURE 13: Power in band 0.05-0.1 Hz;
     % FEATURE 14: Power in band 0.1-0.25 Hz;
      % help from Kaustubh Supekar, 8/9/2012;
      % First define our buckets:;
     bucket_starts = [0 0.008 0.02 0.05 0.1];
     bucket_ends = [0.008 0.02 0.05 0.1 0.25];
     start_index = 0;
          for i=1:length(bucket_starts)
          bucket_start_freq = bucket_starts(i);
 % starting frequency of your bucket;
         bucket_end_freq = bucket_ends(i);
   % end frequency of your bucket;
          %ts = rand(180,1);
 % ts is timeseries data. replace it with actual data.;
         ntime = length(T);
         nfft = floor(ntime/2);
          bucket_start_index = floor(nfft*bucket_start_freq)/(1/(2*TR));
         bucket_end_index = floor(nfft*bucket_end_freq)/(1/(2*TR));
             % chosen to remove components having most of the energy in the range f > 0.1 Hz;
         bucket_start_index = round(bucket_start_index);
         bucket_end_index = round(bucket_end_index);
          % compute fft;
         temp = abs(fft(T, ntime));
         freq_data = temp(1:floor(ntime/2));
 % just take half the spectrum (because fft is symmetric);
         % This spits out a warning, but I think that it's OK;
          % compute energy in the bucket;
         bucket_energy = 0;
         for column = bucket_start_index+1:bucket_end_index-1
                 bucket_energy = bucket_energy + freq_data(column)^2;
         end
         feature(start_index + i) = bucket_energy;
          end
 end