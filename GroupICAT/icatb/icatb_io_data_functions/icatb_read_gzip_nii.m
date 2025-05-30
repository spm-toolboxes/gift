function varargout = icatb_read_gzip_nii(fileIn, varargin)
%% Read data from gzip nifti file (*.nii.gz) directly using GZIPInputstream.
%
% Inputs:
%
% 1. fileIn - Nifti gzip file name
% 2. varargin - Variable arguments passed in pairs
%
%   a. read_hdr_only - Optional argument. By default, both header and data information is returned. If set to 1, only necessary fields in header
%   are returned (slices and timeNo variables are ignored).
%   b. slices - Axial slice/slices. You could enter row vector of slices. By
%   default, all slices are loaded.
%   c. timepoints - Timepoints of interest. By default, all timepoints are
%   returned.
%   d.mask - Mask of interest. Specify full file path or use boolean mask
%   or indices.
%   e. use_spm -  Gzip files are un-zipped and spm volume functions are used to read nifti
%   files
%   f. buffer_size - Default buffer size is set to 2^14 bytes (memory efficient) when reading
%   using GZIPInputstream. Max buffer size you could specify is 2^31-1.
%
% Outputs:
% [hdr, V] - if read_hdr_only == 1. hdr is header and V is spm volume
% structure.
% [data, hdr, V] if read_hdr_only == 0. Data is 4D array (x,y,z,t) or 2D
% array (x*y*z, t) if mask is specified, hdr is header and V os spm volume structure.
%
%

icatb_defaults;
global NIFTI_GZ;
global GZIPINFO;

%% Parse inputs
read_hdr_only = 0;
buffer_size = 2^14;
isLargeFile = 0;
try
    buffer_size = GZIPINFO.buffer_size;
catch
end

try
    isLargeFile = GZIPINFO.isLargeFile;
catch
end

tmp_dir = [];
try
    tmp_dir = GZIPINFO.tempdir;
catch
end

if (isempty(tmp_dir))
    GZIPINFO.tempdir = tempdir;
end

isSPMRead = NIFTI_GZ;
if (isempty(isSPMRead))
    isSPMRead = 0;
end
slices = [];
timeNo = [];

for n = 1:2:length(varargin)
    if (strcmpi(varargin{n}, 'read_hdr_only'))
        read_hdr_only = varargin{n + 1};
    elseif (strcmpi(varargin{n}, 'slices'))
        slices = varargin{n + 1};
    elseif (strcmpi(varargin{n}, 'timepoints') || strcmpi(varargin{n}, 'time'))
        timeNo = varargin{n + 1};
    elseif (strcmpi(varargin{n}, 'mask'))
        mask = varargin{n + 1};
    elseif (strcmpi(varargin{n}, 'use_spm'))
        isSPMRead = varargin{n + 1};
    elseif (strcmpi(varargin{n}, 'buffer_size'))
        buffer_size = varargin{n + 1};
    end
end

if (nargout > 3)
    error('Max number of output arguments can be returned is 3');
end

if (read_hdr_only)
    if (nargout > 2)
        error('Max number of output arguments can be returned is 2 with read header only');
    end
end

if (~usejava('jvm'))
    error('Requires jvm to read gzip nifti (*.nii.gz) file');
end

jar_p = fileparts(which('icatb_read_gzip_nii.m'));

if (~isdeployed)
    javaaddpath(fullfile(jar_p, 'icatb_gz.jar'));
end

import icatb_gz.*;

if (~isSPMRead)
    try
        zclass = icatb_gz.read_gzip();
    catch
        isSPMRead = 1;
    end
end


fileInfo = check_nifti_file_type(fileIn);

fileType = fileInfo.fileType;
hdr_size = fileInfo.hdr_size;
doSwapBytes = fileInfo.swapBytes;
dimBytes = fileInfo.dimBytes;
numBytesToSkip = fileInfo.numBytesToSkip;
fileInfo.read_hdr_only = read_hdr_only;

%% Use GZIPInputstream
if (read_hdr_only)
    
    fid  = java.io.FileInputStream(fileIn);
    zid  = java.util.zip.GZIPInputStream(fid);
    
    nBytesToRead = hdr_size;
    
    
    if (nargout == 1)
        
        zid.skip(numBytesToSkip);
        
        if (~isSPMRead)
            inByteArray = zclass.read(zid, dimBytes);
        else
            inByteArray = readInitialBytes(zid, dimBytes);
        end
    else
        if (~isSPMRead)
            inByteArray = zclass.read(zid, nBytesToRead);
        else
            inByteArray = readInitialBytes(zid, nBytesToRead);
        end
    end
    try
        zid.close();
        fid.close();
    catch
    end
    hdr = read_hdr(inByteArray, fileInfo);
    if (nargout > 1)
        gzV = getVol(fileIn, hdr);
    end
    
else
    
    if (~isSPMRead)
        [inByteArray, hdr] = readGzip(fileIn, buffer_size, isLargeFile, fileInfo);
        if (isempty(inByteArray))
            if (~isdeployed)
                clear zclass;
                javarmpath(fullfile(jar_p, 'icatb_gz.jar'));
            end
            msk = [];
            if (exist('mask', 'var') && ~isempty(mask))
                msk = mask;
            end
            [data, HInfo, gzV] = icatb_read_gzip_nii(fileIn, 'read_hdr_only', 0, 'use_spm', 1, 'slices', slices, 'timepoints', timeNo, 'mask', msk);
            varargout{1} = data;
            varargout{2} = HInfo;
            varargout{3} = gzV;
            return;
        end
        gzV = getVol(fileIn, hdr);
    else
        % Uncompress file and read header
        [hdr, orig_gzfn, gzV, XYZ] = getSpmVol(fileIn, timeNo);
    end
    
end

if (read_hdr_only)
    
    varargout{1} = hdr;
    if (nargout == 2)
        varargout{2} = gzV;
    end
    
    return;
    
end

dims = hdr.dim(2:5);

if (~exist('slices', 'var') || isempty(slices))
    slices = 1:dims(3);
end

if (~exist('timeNo', 'var') || isempty(timeNo))
    timeNo = 1:dims(4);
end


byteA = double(hdr.bitpix / 8);

convertDataTo2D = 1;

%% Mask
if (exist('mask', 'var') && ~isempty(mask))
    if (ischar(mask))
        mask = icatb_loadData(mask);
    end
    if (numel(mask) ~= prod(dims(1:3)))
        maskF = zeros(dims(1:3));
        maskF(mask) = 1;
    else
        maskF = mask;
    end
    maskF = reshape(maskF, dims(1:3));
else
    convertDataTo2D = 0;
    maskF = (ones(dims(1:3)) ~= 0);
end

mask_inds = find(maskF(:, :, slices) ~= 0);

if (~convertDataTo2D)
    data = zeros(dims(1), dims(2), length(slices), length(timeNo));
else
    data = zeros(length(mask_inds), length(timeNo));
end


for t = 1:length(timeNo)
    endT = 0;
    for z = 1:length(slices)
        startT = endT  + 1;
        
        if (~isSPMRead)
            
            if (convertDataTo2D)
                mInds = find(maskF(:, :, slices(z)) ~= 0);
            end
            
            position =  double(byteA*((timeNo(t)-1)*prod(dims(1:3)) + (slices(z)-1)*prod(dims(1:2)))) + double(hdr.vox_offset);
            
            tmp = inByteArray(position + 1: position + dims(1)*dims(2)*byteA);
            
            if (~convertDataTo2D)
                if (~doSwapBytes)
                    tmp = double(typecast(tmp, hdr.precision));
                else
                    tmp = double(swapbytes(typecast(tmp, hdr.precision)));
                end
                tmpDat = reshape(tmp, [dims(1), dims(2)]);
            else
                if (~doSwapBytes)
                    tmpDat = double(typecast(tmp, hdr.precision));
                else
                    tmpDat = double(swapbytes(typecast(tmp, hdr.precision)));
                end
                tmpDat = tmpDat(mInds);
            end
            
            endT = endT + length(tmpDat);
            
        else
            
            mInds = find(maskF(:, :, slices(z)) ~= 0);
            tmpa = squeeze(XYZ(1, :, :, slices(z)));
            tmpb = squeeze(XYZ(2, :, :, slices(z)));
            tmpa = tmpa(mInds);
            tmpb = tmpb(mInds);
            tmpDat = [];
            if (~isempty(mInds))
                tmpDat = icatb_spm_sample_vol(gzV(t), tmpa, tmpb, slices(z)*ones(size(mInds)), 0);
            end
            endT = endT + length(tmpDat);
            if (~convertDataTo2D)
                tmpDat = reshape(tmpDat, dims(1), dims(2));
            end
            
        end
        
        clear tmp;
        
        if (~convertDataTo2D)
            data(:, :, z, t) = tmpDat;
        else
            data(startT:endT, t) = tmpDat;
        end
        
    end
    
end


if (~isSPMRead)
    if (hdr.scl_slope ~=0)
        data = data*hdr.scl_slope + hdr.scl_inter;
    end
end

data (isfinite(data) == 0) = 0;

varargout{1} = data;
varargout{2} = hdr;

if (nargout == 3)
    varargout{3} = gzV(1);
end

if (exist('orig_gzfn', 'var'))
    doCleanUpFiles(orig_gzfn);
end



function hdr = read_hdr(inByteArray, fileInfo)
%% Read header

%doSwapBytes = 0;
doSwapBytes = fileInfo.swapBytes;
read_hdr_only = fileInfo.read_hdr_only;
fileType = fileInfo.fileType;
dimBytes = fileInfo.dimBytes;

precision_types = {'uint8', 'int16', 'int32', 'single', 'double', 'int8', 'uint16', 'uint32'};
codes   = [2, 4, 8, 16, 64, 256, 512, 768];

% necessary fields
%if (read_hdr_only)
if (length(inByteArray) == dimBytes)
    dim = typecast(inByteArray, ['int', num2str(dimBytes)]);
    %if (dim(1) < 1 || dim(1) > 7)
    if (doSwapBytes)
        %doSwapBytes = 1;
        dim = swapbytes(typecast(inByteArray, ['int', num2str(dimBytes)]));
    end
    hdr.dim = dim(:)';
    return;
end


% chk = typecast(inByteArray(41:56), 'int16');
% if (chk(1) < 1 || chk(1) > 7)
%     doSwapBytes = 1;
% end

if (strcmpi(fileType, 'nifti1'))
    
    fieldsIn  = {   'dim',                'int16',  (41:56);
        'datatype',           'int16',  (71:72);
        'bitpix',             'int16',  (73:74);
        'vox_offset',         'single', (109:112);
        'pixdim',             'single', (77:108);
        'scl_slope',          'single', (113:116);
        'scl_inter',          'single', (117:120);
        'qform_code',         'int16',  (253:254);
        'sform_code',         'int16',  (255:256);
        'quatern_b',          'single', (257:260);
        'quatern_c',          'single', (261:264);
        'quatern_d',          'single', (265:268);
        'qoffset_x',          'single', (269:272);
        'qoffset_y',          'single', (273:276);
        'qoffset_z',          'single', (277:280);
        'sizeof_hdr',         'int32',  (1:4);
        'data_type',          'char',   (5:14);
        'db_name',            'char',   (15:32);
        'extents',            'int32',  (33:36);
        'session_error',      'int16',  (37:38);
        'regular',            'char',   (39:39);
        'dim_info',           'uint8',   (40:40);
        'intent_p1',          'single', (57:60);
        'intent_p2',          'single', (61:64);
        'intent_p3',          'single', (65:68);
        'intent_code',        'int16',  (69:70);
        'slice_start',        'int16',  (75:76);
        'slice_end',          'int16',  (121:122);
        'slice_code',         'uint8',   (123:123);
        'xyzt_units',         'uint8',   (124:124);
        'cal_max',            'single', (125:128);
        'cal_min',            'single', (129:132);
        'slice_duration',     'single', (133:136);
        'toffset',            'single', (137:140);
        'glmax',              'single', (141:144);
        'glmin',              'single', (145:148);
        'descrip',            'char',   (149:228);
        'aux_file',           'char',   (229:252);
        'srow_x',             'single', (281:296);
        'srow_y',             'single', (297:312);
        'srow_z',             'single', (313:328);
        'intent_name',        'char',   (329:344);
        'magic',              'char',   (345:348)};
    
else
    
    % NIfti 2
    fieldsIn  = {   'magic',              'char',       (5:12);
        'datatype',          'int16',      (13:14);
        'bitpix',             'int16',      (15:16);
        'dim',                'int64',      (17:80);
        'intent_p1',          'double',     (81:88);
        'intent_p2',          'double',     (89:96);
        'intent_p3',          'double',     (97:104);
        'pixdim',             'double',     (105:168);
        'vox_offset',         'int64',      (169:176);
        'scl_slope',          'double',     (177:184);
        'scl_inter',          'double',     (185:192);
        'cal_max',            'double',     (193:200);
        'cal_min',            'double',     (201:208);
        'slice_duration',     'double',     (209:216);
        'toffset',            'double',     (217:224);
        'slice_start',        'int64',      (225:232);
        'slice_end',          'int64',      (233:240);
        'descrip',            'char',       (241:320);
        'aux_file',           'char',       (321:344);
        'qform_code',         'int32',      (345:348);
        'sform_code',         'int32',      (349:352);
        'quatern_b',          'double',     (353:360);
        'quatern_c',          'double',     (361:368);
        'quatern_d',          'double',     (369:376);
        'qoffset_x',          'double',     (377:384);
        'qoffset_y',          'double',     (385:392);
        'qoffset_z',          'double',     (393:400);
        'srow_x',             'double',     (401:432);
        'srow_y',             'double',     (433:464);
        'srow_z',             'double',     (465:496);
        'slice_code',         'int32',      (497:500);
        'xyzt_units',         'int32',      (501:504);
        'intent_code',        'int32',      (505:508);
        'intent_name',        'char',       (509:524);
        'dim_info',           'char',       (525:525);
        'unused_str',         'char',       (526:540);
        };
    
    
end

for nF = 1:size(fieldsIn, 1)
    if (strcmpi(fieldsIn{nF, 2}, 'char'))
        tmp = char(inByteArray(fieldsIn{nF, 3}));
        if (size(tmp, 1) > 1)
            tmp = tmp';
        end
    else
        if (~doSwapBytes)
            tmp = typecast(inByteArray(fieldsIn{nF, 3}), fieldsIn{nF, 2});
        else
            tmp = swapbytes(typecast(inByteArray(fieldsIn{nF, 3}), fieldsIn{nF, 2}));
        end
    end
    if (isnumeric(tmp))
        tmp = double(tmp(:)');
    end
    hdr.(fieldsIn{nF, 1}) = tmp;
end

if (~hdr.scl_slope && ~hdr.scl_inter)
    hdr.scl_slope = 1;
end

hdr.dim = hdr.dim(:)';
hdr.pixdim = hdr.pixdim(:)';

hdr.precision = [];
chk = find(codes == hdr.datatype);
if (~isempty(chk))
    hdr.precision = precision_types{chk};
end

if isempty(hdr.precision)
    error('Unknown data type');
end


function [inByteArray, hdr] = readGzip(fileIn, buffer_size, isLargeFile, fileInfo)
%% Read large data in chunks
%

import icatb_gz.*;
zclass = icatb_gz.read_gzip();
hdrSize = fileInfo.hdr_size;

%tmpFileInfo = dir(fileIn);
%tmpGBytes = tmpFileInfo(1).bytes/1024/1024/1024;

% if (tmpGBytes > 0.5)
%     isLargeFile = 1;
% end

try
    
    if (isLargeFile)
        
        fid  = java.io.FileInputStream(fileIn);
        zid  = java.util.zip.GZIPInputStream(fid);
        
        try
            
            hdrBytes = zclass.read(zid, hdrSize);
            
            hdr = read_hdr(typecast(hdrBytes, 'uint8'), fileInfo);
            
            voxel_offset = hdr.vox_offset;
            bytesA = hdr.bitpix/8;
            byte_array_size = voxel_offset + prod(hdr.dim(2:5))*bytesA;
            inByteArray = zeros(byte_array_size, 1, 'int8');
            inByteArray(1:hdrSize) = hdrBytes;
            zid.close();
            fid.close();
            
            fid  = java.io.FileInputStream(fileIn);
            zid  = java.util.zip.GZIPInputStream(fid);
            zid.skip(voxel_offset);
            count = voxel_offset;
            while 1
                
                count = count + 1;
                
                tmp = zclass.read(zid, buffer_size);
                
                len = length(tmp);
                
                if (len == 0)
                    break;
                end
                
                endCount = count + len - 1;
                inByteArray(count:endCount) = tmp;
                count = endCount;
                
            end
            
            inByteArray = typecast(inByteArray, 'uint8');
            
            zid.close();
            fid.close();
            
        catch
            
            
            zid.close();
            fid.close();
            
            rethrow(lasterror);
            
        end
        
        
    else
        
        inByteArray = zclass.read(fileIn, buffer_size);
        inByteArray = typecast(inByteArray, 'uint8');
        hdr = read_hdr(inByteArray, fileInfo);
        
    end
    
catch
    
    disp('Unzipping gzip file to temporary directory and using spm volume functions for very large gzip data-sets.');
    disp(' ');
    inByteArray  = [];
    hdr = [];
    doSwapBytes = [];
    
end

function V = getVol(fname, hdr)
%% Create spm volume structure from header

fname_i = fname;
[pathstr, fn, extn] = fileparts(fname);

extn = strrep(lower(extn), '.gz', '');
fname = fullfile(pathstr, [fn, extn]);

%mat = decode_qform0(hdr);

mat = getqform(hdr);

V   = struct('fname', fname,...
    'dim',   hdr.dim(2:4),...
    'dt',   [hdr.datatype, 0],...
    'pinfo', [hdr.scl_slope hdr.scl_inter hdr.vox_offset]',...
    'mat',   mat,...
    'n',     1,...
    'descrip', 'NIFTI');

h = icatb_nifti;
h.mat = V.mat;
h.mat0 = V.mat;
fp  = fopen(fname_i, 'r', 'native');
[~,~,mach] = fopen(fp);
fclose(fp);
dat = icatb_file_array(V.fname, hdr.dim(2:5),[hdr.datatype, strfind(mach,'be')], hdr.vox_offset, hdr.scl_slope, hdr.scl_inter);
h.dat = dat;
h.diminfo.slice = 3;
h.diminfo.slice_time.code = hdr.slice_code;
h.diminfo.slice_time.start = hdr.slice_start+1;
h.diminfo.slice_time.end = hdr.slice_end+1;
h.timing.toffset = hdr.toffset;
h.timing.tspace = hdr.pixdim(5);
matcodes = {'UNKNOWN', 'Scanner', 'Aligned', 'Talairach', 'MNI152'};
h.mat_intent = matcodes{hdr.sform_code+1};
h.mat0_intent = matcodes{hdr.qform_code+1};
V.private = h;


function M = decode_qform0(hdr)
% Decode qform info from NIFTI-1 headers.
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

%
% $Id: decode_qform0.m 3131 2009-05-18 15:54:10Z guillaume $


dim    = double(hdr.dim);
pixdim = double(hdr.pixdim);
if ~isfield(hdr,'magic') || hdr.qform_code <= 0,
    flp = icatb_spm_flip_analyze_images;
    %disp('------------------------------------------------------');
    %disp('The images are in a form whereby it is not possible to');
    %disp('tell the left and right sides of the brain apart.');
    %if flp,
    %    disp('They are assumed to be stored left-handed.');
    %else
    %    disp('They are assumed to be stored right-handed.');
    %end;
    %disp('------------------------------------------------------');
    
    %R     = eye(4);
    n      = min(dim(1),3);
    vox    = [pixdim(2:(n+1)) ones(1,3-n)];
    
    if ~isfield(hdr,'origin') || ~any(hdr.origin(1:3)),
        origin = (dim(2:4)+1)/2;
    else
        origin = double(hdr.origin(1:3));
    end;
    off     = -vox.*origin;
    M       = [vox(1) 0 0 off(1) ; 0 vox(2) 0 off(2) ; 0 0 vox(3) off(3) ; 0 0 0 1];
    
    % Stuff for default orientations
    if flp, M = diag([-1 1 1 1])*M; end;
else
    
    % Rotations from quaternions
    R = Q2M(double([hdr.quatern_b hdr.quatern_c hdr.quatern_d]));
    
    % Translations
    T = [eye(4,3) double([hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z 1]')];
    
    % Zooms.  Note that flips are derived from the first
    % element of pixdim, which is normally unused.
    n = min(dim(1),3);
    Z = [pixdim(2:(n+1)) ones(1,4-n)];
    Z(Z<0) = 1;
    if pixdim(1)<0, Z(3) = -Z(3); end;
    Z = diag(Z);
    
    M = T*R*Z;
    
    % Convert from first voxel at [1,1,1]
    % to first voxel at [0,0,0]
    M = M * [eye(4,3) [-1 -1 -1 1]'];
end;
return;



function M = Q2M(Q)
% Generate a rotation matrix from a quaternion xi+yj+zk+w,
% where Q = [x y z], and w = 1-x^2-y^2-z^2.
% See: http://skal.planet-d.net/demo/matrixfaq.htm
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

%
% $Id: Q2M.m 1143 2008-02-07 19:33:33Z spm $


Q = Q(1:3); % Assume rigid body
w = sqrt(1 - sum(Q.^2));
x = Q(1); y = Q(2); z = Q(3);
if w<1e-7,
    w = 1/sqrt(x*x+y*y+z*z);
    x = x*w;
    y = y*w;
    z = z*w;
    w = 0;
end;
xx = x*x; yy = y*y; zz = z*z; ww = w*w;
xy = x*y; xz = x*z; xw = x*w;
yz = y*z; yw = y*w; zw = z*w;
M = [...
    (xx-yy-zz+ww)      2*(xy-zw)      2*(xz+yw) 0
    2*(xy+zw) (-xx+yy-zz+ww)      2*(yz-xw) 0
    2*(xz-yw)      2*(yz+xw) (-xx-yy+zz+ww) 0
    0              0              0  1];
return;


function varargout = getSpmVol(fileIn, timeNo)
%% Unzip file and read info
%

global GZIPINFO;

gzfn = gunzip (fileIn, GZIPINFO.tempdir);
orig_gzfn = char(gzfn);

if (nargout > 2)
    gzfn = icatb_rename_4d_file(orig_gzfn);
    if (~exist('timeNo', 'var') || isempty(timeNo))
        timeNo = (1:size(gzfn, 1));
    end
    gzV = icatb_spm_vol(deblank(gzfn(timeNo, :)));
    hdr = gzV(1).private.hdr;
    
    hdr.dim = double(hdr.dim);
    
else
    
    hdr = icatb_read_hdr(deblank(orig_gzfn));
    hdr.dim = double(hdr.dime.dim);
    
end

varargout{1} = hdr;
varargout{2} = orig_gzfn;

if (nargout >= 3)
    varargout{3} = gzV;
end

if (nargout == 4)
    XYZ = icatb_get_voxel_coords(gzV(1).dim(1:3));
    XYZ = reshape(XYZ, [3, gzV(1).dim(1:3)]);
    varargout{4} = XYZ;
end


function doCleanUpFiles(orig_gzfn)

try
    for nF = 1:size(orig_gzfn, 1)
        delete(deblank(orig_gzfn(nF, :)));
    end
catch
end

function inByteArray = readInitialBytes(zid, nBytesToRead)
%% Use read method in matlab
%

if (isfinite(nBytesToRead))
    inByteArray = zeros(nBytesToRead, 1, 'uint8');
else
    inByteArray = [];
    inByteArray = uint8(inByteArray);
end

count = 0;
tmp = 0;
while ((tmp ~= -1) && (count < nBytesToRead))
    count = count + 1;
    tmp = uint8(read(zid));
    inByteArray(count) = tmp;
end



function entry = findindict(c,dcode)
% Look up an entry in the dictionary
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

%
% $Id: findindict.m 1143 2008-02-07 19:33:33Z spm $


entry = [];
d = getdict;
d = d.(dcode);
if ischar(c)
    for i=1:length(d),
        if strcmpi(d(i).label,c),
            entry = d(i);
            break;
        end;
    end;
elseif isnumeric(c) && numel(c)==1
    for i=1:length(d),
        if d(i).code==c,
            entry = d(i);
            break;
        end;
    end;
else
    error(['Inappropriate code for ' dcode '.']);
end;
if isempty(entry)
    fprintf('\nThis is not an option.  Try one of these:\n');
    for i=1:length(d)
        fprintf('%5d) %s\n', d(i).code, d(i).label);
    end;
    %fprintf('\nNO CHANGES MADE\n');
end;

function d = getdict
% Dictionary of NIFTI stuff
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

%
% $Id: getdict.m 1143 2008-02-07 19:33:33Z spm $


persistent dict;
if ~isempty(dict),
    d = dict;
    return;
end;

% Datatype
t = true;
f = false;
table = {...
    0   ,'UNKNOWN'   ,'uint8'   ,@uint8  ,1,1  ,t,t,f
    1   ,'BINARY'    ,'uint1'   ,@logical,1,1/8,t,t,f
    256 ,'INT8'      ,'int8'    ,@int8   ,1,1  ,t,f,t
    2   ,'UINT8'     ,'uint8'   ,@uint8  ,1,1  ,t,t,t
    4   ,'INT16'     ,'int16'   ,@int16  ,1,2  ,t,f,t
    512 ,'UINT16'    ,'uint16'  ,@uint16 ,1,2  ,t,t,t
    8   ,'INT32'     ,'int32'   ,@int32  ,1,4  ,t,f,t
    768 ,'UINT32'    ,'uint32'  ,@uint32 ,1,4  ,t,t,t
    1024,'INT64'     ,'int64'   ,@int64  ,1,8  ,t,f,f
    1280,'UINT64'    ,'uint64'  ,@uint64 ,1,8  ,t,t,f
    16  ,'FLOAT32'   ,'float32' ,@single ,1,4  ,f,f,t
    64  ,'FLOAT64'   ,'double'  ,@double ,1,8  ,f,f,t
    1536,'FLOAT128'  ,'float128',@crash  ,1,16 ,f,f,f
    32  ,'COMPLEX64' ,'float32' ,@single ,2,4  ,f,f,f
    1792,'COMPLEX128','double'  ,@double ,2,8  ,f,f,f
    2048,'COMPLEX256','float128',@crash  ,2,16 ,f,f,f
    128 ,'RGB24'     ,'uint8'   ,@uint8  ,3,1  ,t,t,f};

dtype = struct(...
    'code'     ,table(:,1),...
    'label'    ,table(:,2),...
    'prec'     ,table(:,3),...
    'conv'     ,table(:,4),...
    'nelem'    ,table(:,5),...
    'size'     ,table(:,6),...
    'isint'    ,table(:,7),...
    'unsigned' ,table(:,8),...
    'min',-Inf,'max',Inf',...
    'supported',table(:,9));
for i=1:length(dtype),
    if dtype(i).isint
        if dtype(i).unsigned
            dtype(i).min =  0;
            dtype(i).max =  2^(8*dtype(i).size)-1;
        else
            dtype(i).min = -2^(8*dtype(i).size-1);
            dtype(i).max =  2^(8*dtype(i).size-1)-1;
        end;
    end;
end;
% Intent
table = {...
    0   ,'NONE'         ,'None',{}
    2   ,'CORREL'       ,'Correlation statistic',{'DOF'}
    3   ,'TTEST'        ,'T-statistic',{'DOF'}
    4   ,'FTEST'        ,'F-statistic',{'numerator DOF','denominator DOF'}
    5   ,'ZSCORE'       ,'Z-score',{}
    6   ,'CHISQ'        ,'Chi-squared distribution',{'DOF'}
    7   ,'BETA'         ,'Beta distribution',{'a','b'}
    8   ,'BINOM'        ,'Binomial distribution',...
    {'number of trials','probability per trial'}
    9   ,'GAMMA'        ,'Gamma distribution',{'shape','scale'}
    10  ,'POISSON'      ,'Poisson distribution',{'mean'}
    11  ,'NORMAL'       ,'Normal distribution',{'mean','standard deviation'}
    12  ,'FTEST_NONC'   ,'F-statistic noncentral',...
    {'numerator DOF','denominator DOF','numerator noncentrality parameter'}
    13  ,'CHISQ_NONC'   ,'Chi-squared noncentral',{'DOF','noncentrality parameter'}
    14  ,'LOGISTIC'     ,'Logistic distribution',{'location','scale'}
    15  ,'LAPLACE'      ,'Laplace distribution',{'location','scale'}
    16  ,'UNIFORM'      ,'Uniform distribition',{'lower end','upper end'}
    17  ,'TTEST_NONC'   ,'T-statistic noncentral',{'DOF','noncentrality parameter'}
    18  ,'WEIBULL'      ,'Weibull distribution',{'location','scale','power'}
    19  ,'CHI'          ,'Chi distribution',{'DOF'}
    20  ,'INVGAUSS'     ,'Inverse Gaussian distribution',{'mu','lambda'}
    21  ,'EXTVAL'       ,'Extreme Value distribution',{'location','scale'}
    22  ,'PVAL'         ,'P-value',{}
    23  ,'LOGPVAL'      ,'Log P-value',{}
    24  ,'LOG10PVAL'    ,'Log_10 P-value',{}
    1001,'ESTIMATE'     ,'Estimate',{}
    1002,'LABEL'        ,'Label index',{}
    1003,'NEURONAMES'   ,'NeuroNames index',{}
    1004,'MATRIX'       ,'General matrix',{'M','N'}
    1005,'MATRIX_SYM'   ,'Symmetric matrix',{}
    1006,'DISPLACEMENT' ,'Displacement vector',{}
    1007,'VECTOR'       ,'Vector',{}
    1008,'POINTS'       ,'Pointset',{}
    1009,'TRIANGLE'     ,'Triangle',{}
    1010,'QUATERNION'   ,'Quaternion',{}
    1011,'DIMLESS'      ,'Dimensionless',{}
    };
intent = struct('code',table(:,1),'label',table(:,2),...
    'fullname',table(:,3),'param',table(:,4));

% Units
table = {...
    0,   1,'UNKNOWN'
    1,1000,'m'
    2,   1,'mm'
    3,1e-3,'um'
    8,   1,'s'
    16,1e-3,'ms'
    24,1e-6,'us'
    32,   1,'Hz'
    40,   1,'ppm'
    48,   1,'rads'};
units = struct('code',table(:,1),'label',table(:,3),'rescale',table(:,2));

% Reference space
% code  = {0,1,2,3,4};
table = {...
    0,'UNKNOWN'
    1,'Scanner Anat'
    2,'Aligned Anat'
    3,'Talairach'
    4,'MNI_152'};
anat  = struct('code',table(:,1),'label',table(:,2));

% Slice Ordering
table = {...
    0,'UNKNOWN'
    1,'sequential_increasing'
    2,'sequential_decreasing'
    3,'alternating_increasing'
    4,'alternating_decreasing'};
sliceorder = struct('code',table(:,1),'label',table(:,2));

% Q/S Form Interpretation
table = {...
    0,'UNKNOWN'
    1,'Scanner'
    2,'Aligned'
    3,'Talairach'
    4,'MNI152'};
xform = struct('code',table(:,1),'label',table(:,2));

dict = struct('dtype',dtype,'intent',intent,'units',units,...
    'space',anat,'sliceorder',sliceorder,'xform',xform);

d = dict;
return;

function varargout = crash(varargin)
error('There is a NIFTI-1 data format problem (an invalid datatype).');


function t = getqform(h)

if h.sform_code > 0
    t = double([h.srow_x ; h.srow_y ; h.srow_z ; 0 0 0 1]);
    t = t * [eye(4,3) [-1 -1 -1 1]'];
else
    t = decode_qform0(h);
end
s = double(bitand(h.xyzt_units,7));
if s
    d = findindict(s,'units');
    t = diag([d.rescale*[1 1 1] 1])*t;
end;


function fileInfo = check_nifti_file_type(fileName)
% Check nifti type and get additional info

fid  = java.io.FileInputStream(fileName);
zid  = java.util.zip.GZIPInputStream(fid);


initBytes = readInitialBytes(zid, 4);


try
    zid.close();
    fid.close();
catch
end


hdr_size = typecast(initBytes, 'int32');
doSwapBytes = 0;
if (isempty(hdr_size) || ((hdr_size ~= 348) && (hdr_size ~= 540)))
    hdr_size = swapbytes(hdr_size);
    doSwapBytes = 1;
end

if (hdr_size == 348)
    numBytesToSkip = 40;
    fileType = 'nifti1';
    dimBytes = 16;
elseif (hdr_size == 540)
    numBytesToSkip = 16;
    fileType = 'nifti2';
    dimBytes = 64;
else
    error('File is not Nifti1 or Nifti2');
end


fileInfo.numBytesToSkip = numBytesToSkip;
fileInfo.dimBytes = dimBytes;
fileInfo.fileType = fileType;
fileInfo.swapBytes = doSwapBytes;
fileInfo.hdr_size = hdr_size;