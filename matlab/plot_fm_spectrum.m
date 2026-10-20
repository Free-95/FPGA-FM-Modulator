%% Vivado ILA-plotted FM Modulation Verification using Frequency Spectrum
clear; clc; close all;

% Load CSV and extract Column 6 (ModulatedSignalOut)
data = readmatrix('iladata.csv');
fm_sig = data(:, 6);
fm_sig = fm_sig(~isnan(fm_sig));  % Remove any header NaN rows

% Compute FFT at 200 MHz Sampling Rate
Fs = 200e6;
N = length(fm_sig);
N_fft = 2^20;        % Zero-pad for smooth frequency curve

Y = fft((fm_sig - mean(fm_sig)) .* hann(N), N_fft);
P_dB = 20*log10(abs(Y(1:N_fft/2+1)) + eps);
P_dB = P_dB - max(P_dB);      % Normalize peak to 0 dB
f_MHz = (0:N_fft/2) * (Fs / N_fft) / 1e6;

% Plot Frequency Spectrum around 10.7 MHz
figure;
plot(f_MHz, P_dB, 'b', 'LineWidth', 1.5);
grid on;
xlim([10.5, 10.9]);
ylim([-60, 5]);
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
title('Frequency Modulated Signal Spectrum');

% Reference lines for Center (10.7 MHz) and +/- 75 kHz Deviation
xline(10.700, 'k--', '10.7 MHz (Carrier)');
xline(10.625, 'r--', '10.625 MHz (-75 kHz)');
xline(10.775, 'r--', '10.775 MHz (+75 kHz)');