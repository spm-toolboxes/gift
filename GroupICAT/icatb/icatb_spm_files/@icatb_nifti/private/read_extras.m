function extras = read_extras(fname)
% Read extra bits of information
%__________________________________________________________________________
% Copyright (C) 2005-2018 Wellcome Trust Centre for Neuroimaging

%
% $Id: read_extras.m 7370 2018-07-09 10:44:51Z guillaume $


extras = struct;
[pth,nam,ext] = fileparts(fname);
switch ext
    case {'.hdr','.img','.nii'}
        mname = fullfile(pth,[nam '.mat']);
    case {'.HDR','.IMG','.NII'}
        mname = fullfile(pth,[nam '.MAT']);
    otherwise
        mname = fullfile(pth,[nam '.mat']);
end

try
    is_extra = icatb_spm_existfile(mname);
catch
    is_extra = exist(mname,'file') > 0;
end

if is_extra
    try
        extras = load(mname);
    catch
        warning('Can not load "%s" as a binary MAT file.', mname);
    end
end
