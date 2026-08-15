project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'functions'));
addpath(fullfile(project_root, 'sub_functions'));

cases = [
    deg2rad(20.68), deg2rad(130.0), deg2rad(17.5),  deg2rad(-61.8), deg2rad(40.0), deg2rad(15.0);
    deg2rad(35.00), deg2rad(210.0), deg2rad(-42.0), deg2rad(110.0), deg2rad(25.0), deg2rad(80.0)
];

for i = 1:size(cases, 1)
    E = cases(i, 1);
    A = cases(i, 2);
    B = cases(i, 3);
    L = cases(i, 4);
    z = cases(i, 5);
    t_r = cases(i, 6);

    [actual_lat, actual_lon] = Get_IPP_kent(E, A, B, L, z, t_r);

    ipp_arc = pi / 2 - E - z;
    expected_lat = asin(cos(ipp_arc) * sin(B) + sin(ipp_arc) * cos(B) * cos(A));

    if (B > deg2rad(70) && tan(ipp_arc) * cos(A) > tan(pi / 2 - B)) || ...
            (B < -deg2rad(70) && -tan(ipp_arc) * cos(A) > tan(pi / 2 + B))
        expected_lon = L + pi - asin(sin(ipp_arc) * sin(A) / cos(expected_lat));
    else
        expected_lon = L + asin(sin(ipp_arc) * sin(A) / cos(expected_lat));
    end

    expected_lon = mod(expected_lon + pi, 2 * pi) - pi;
    [expected_lat, expected_lon] = geo2mag(expected_lat, expected_lon);
    expected_lon = expected_lon + t_r - pi;
    expected_lon = mod(expected_lon + pi, 2 * pi) - pi;

    lon_diff = atan2(sin(actual_lon - expected_lon), cos(actual_lon - expected_lon));
    assert(abs(actual_lat - expected_lat) < 1e-12, ...
        'Get_IPP_kent should use the shared geo2mag latitude transform.');
    assert(abs(lon_diff) < 1e-12, ...
        'Get_IPP_kent should use the shared geo2mag longitude transform.');
end
