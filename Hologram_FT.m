% Built off a script from 7/15/20
% Short Distance Fresnel Prop
% Start with some amplitude distribution and propagate a short distance

addpath('./MATLAB_functions/'); %include helper functions
num_pixels = 256;
midpt = num_pixels / 2;
% Parameters; units mm
PARAMS = struct;
PARAMS.Lx = 150e-3;      %x side length of input image
PARAMS.Ly = 150e-3;      %y side length of input image
PARAMS.lambda = 490e-6; %wavelength
PARAMS.Mx = num_pixels;        %x samples
PARAMS.My = num_pixels;        %y samples
PARAMS.NA = 0.1;        %numerical aperture

%Generate fields by Fresnel propagating constant amplitude,
%circular aperture fields two different distances z1 & z2. 
%using propagate(z, parameters)
%the Brooker papers have z1~-10mm, z2~10mm
z1 = -1; %mm
z2 = 1; %mm
p1 = propagate_init(z1, PARAMS);
p2 = propagate_init(z2, PARAMS);
%generate the complex-valued hologram
hol = complex_hologram(p1, p2, 3);

% make a 3D hologram by Fresnel propagating various z distances
z_vals = linspace(-0.75, -0.25, 100);
num_z_vals = size(z_vals);
num_z_vals = num_z_vals(2);
% propagate in the xz plane to speed up the calculation of 3D PSFs

size(hol_yslice);
z_propped = fresnel_prop_xz(hol_yslice, z_vals, PARAMS);
subplot(1, 3, 1)
imagesc(z_vals, hol.x, abs(z_propped));
colormap('gray');
xlabel('z (mm)');
ylabel('x (mm)');
title('Quick 3D PSF');
%for loop method to generate a 3d hologram
hol3d = hologram3D(hol, z_vals, PARAMS);
hol3d_xz_im = squeeze(abs(hol3d.intensity(:,midpt,:)));
subplot(1, 3, 2);
imagesc(hol3d.z, hol3d.x, hol3d_xz_im);
colormap('gray');
xlabel('z (mm)');
ylabel('x (mm)');
title('Full 3D PSF');
hol3d_ft = FT(hol3d);
hol3d_ft_im = squeeze(abs(hol3d_ft.intensity(:,midpt,:)));
subplot(1, 3, 3);
colormap('gray');
imagesc(hol3d_ft.fz, hol3d_ft.fx, hol3d_ft_im);
xlabel('f_z (mm^{-1})');
ylabel('f_x (mm^{-1})');
title ('FT of Full 3D PSF');

function H = fresnel_propagator_xz(z_values, Lx, Mx, lambda)
    arguments
        z_values % propagataion distance
        Lx = 250e-3
        Mx = 1024
        lambda = 490e-6
    end
    % Define Fresnel Propagtor
    dx = Lx/Mx;
    % Define frequency axes
    fMax_x = 1/(2*dx);
    df_x = 1/Lx;
    fx = -fMax_x:df_x:fMax_x-df_x;
    [FX,Z] = meshgrid(fx,z_values);
    quad_phase = exp(-1i*pi*lambda.*((FX.^2).*Z));
    %quad_phase = quad_phase.^Z;
    z_phase = exp(2i*pi/lambda.*Z);
    H = quad_phase .* z_phase;
    % H = exp(2i*pi.*Z./lambda) .* exp(-1i*pi*lambda.*Z.*(FX.^2));
    %H = transpose(H);
end

function propped = fresnel_prop_xz(hol_slice, z_values, bench_params)
    %{
    Propagate an image (assumed to start in real space) a distance zf.
    %}
    arguments
        hol_slice %y slice of a fresnel hologram
        z_values
        bench_params
    end
    %repeat input y slice to broadcast across z values
    num_z_vals = size(z_values);
    im_xz = repmat(hol_slice, [num_z_vals(2), 1]);
    %generate fresnel propagator
    H = fresnel_propagator_xz(z_values, bench_params.Lx, ...
                              bench_params.Mx, bench_params.lambda);
    % Propagate
    im_size = size(im_xz);
    %ft only in x axis (ax=2) 
    % this is because z axis is just used for broadcasting, not propagating
    ft = fft(im_xz, im_size(2), 2);
    proppedFt = ft .* fftshift(H);
    %ifft should also be only in x axis (ax=2)
    propped = transpose(ifftshift(ifft(proppedFt, im_size(2), 2)));
end

function plane_struct = FT(image_struct)
    if isfield(image_struct, 'intensity')
        field_type = 'intensity';
    elseif isfield(image_struct, 'field')
        field_type = 'field';
    else
        fprintf("Struct did not have an 'intensity' or 'field' parameter");
    end
    ft = fftshift(fftn(ifftshift(image_struct.(field_type))));
    %get correct frequency axis
    % Define spatial axes
    dx = image_struct.x(2) - image_struct.x(1);
    dy = image_struct.y(2) - image_struct.y(1);
    lx = image_struct.x(end) - image_struct.x(1);
    ly = image_struct.y(end) - image_struct.y(1);
    % Define frequency axes
    fMax_x = 1/(2*dx);
    fMax_y = 1/(2*dy);
    df_x = 1/lx;
    df_y = 1/ly;
    fx = -fMax_x:df_x:fMax_x-df_x;
    fy = -fMax_y:df_y:fMax_y-df_y;
    plane_struct = struct('intensity', ft, 'fx', fx, 'fy', fy);
    if isfield(image_struct, 'z')
       %compute z frequencies if it's a 3D hologram
       dz = image_struct.z(2) - image_struct.z(1); 
       fMax_z = 1/(2*dz);
       lz = image_struct.z(end) - image_struct.z(1);
       df_z = 1/lz;
       fz = -fMax_z:df_z:fMax_z-df_z;
       plane_struct.fz = fz;
    end
end

%Sanity checks that our Fresnel propagator works correctly are in
%./Test_Scripts/

%Function Definitions are in ./MATLAB_FUNCTIONS