function result = complex_hologram(plane1, plane2, num_angles, noise)
    %{
    Based on Brooker(2021) equation 2.  Generate a complex-valued hologram
    from a series of (num_angles) real-valued holograms.
    %}
    arguments
        plane1 %interference plane we get from propagate()
        plane2 %second interference plane we get from propagate ()
        num_angles %>=3 subdivisions of 2*pi to apply differing phases
        noise = 0;
    end
    inc = 2*pi / num_angles; %we want (num_angles) evenly separated phases
    h_sum = zeros('like', plane1.field);
    for i = 1:num_angles
        prev_angle = mod(inc*(i-1), 2*pi);
        next_angle = mod(inc*(i+1), 2*pi);
        % shifted_h = shifted_hologram(plane, inc*i, bench_params, 250e-3);
        shifted_h = shifted_hologram(plane1, plane2, inc*i, noise);
        phase = exp(1i * prev_angle) - exp(1i * next_angle);
        h_sum = h_sum + shifted_h.intensity .* phase;
    end
    result = struct('intensity', h_sum, 'x', plane1.x, 'y', plane1.y);
end