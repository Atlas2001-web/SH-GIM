function [latitude, longitude, height] = XYZtoBLH_kent(X, Y, Z)
% XYZtoBLH - Convert geocentric Cartesian (X, Y, Z) to geodetic coordinates (latitude, longitude, height)
% INPUT:
%   X, Y, Z: Cartesian coordinates (in meters)
% OUTPUT:
%   latitude: Geodetic latitude (in radians)
%   longitude: Geodetic longitude (in radians)
%   height: Height above the ellipsoid (in meters)

    % WGS84 ellipsoid parameters
    a_WGS84 = 6378137.0000;       % Semi-major axis (meters)
    b_WGS84 = 6356752.3142;       % Semi-minor axis (meters)
    e2 = 1 - (b_WGS84^2 / a_WGS84^2);  % Square of eccentricity

    % Longitude calculation
    longitude = atan2(Y, X);  % Use atan2 for correct quadrant

    % Initial approximation of latitude
    p = sqrt(X^2 + Y^2);  % Distance in the XY plane
    latitude = atan2(Z, p * (1 - e2));  % Initial guess for latitude

    % Iterative computation of latitude and height
    tolerance = 1e-12;  % Convergence tolerance (radians)
    diff = 1;           % Initialize difference for convergence check
    while diff > tolerance
        N = a_WGS84 / sqrt(1 - e2 * sin(latitude)^2);  % Radius of curvature in the prime vertical
        new_latitude = atan2(Z + e2 * N * sin(latitude), p);  % Update latitude
        diff = abs(new_latitude - latitude);  % Check convergence
        latitude = new_latitude;
    end

    % Height calculation
    N = a_WGS84 / sqrt(1 - e2 * sin(latitude)^2);  % Final radius of curvature
    height = p / cos(latitude) - N;  % Height above the ellipsoid

    % Optional: Ensure longitude is in [0, 2*pi] if needed
    % longitude = mod(longitude, 2*pi);
end
