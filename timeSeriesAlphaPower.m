% Plot alpha wave band power in time series

% -- Initialize --
% sampling frequency : 2048Hz
fs = 2048;
% fft interval : 2sec
interval = 2;
% alpha wave band : 8 - 13Hz
alphaBand = [8:13];

prompt = 'Datasets [default: 1]: ';
datasets = input(prompt);
if isempty(datasets)
    datasets = 1;
elseif ~isnumeric(datasets)
    error('Input must be a numeric');
end

prompt = 'Channel numbers [default: 14:18]: ';
channels = input(prompt);
if isempty(channels)
    channels = [14:18];
elseif ~isnumeric(channels)
    error('Input must be a numeric');
end

for dataset = datasets
    n = fs * interval;
    f = (0:n-1)*(fs/n);
    totalTime = length(ALLEEG(dataset).data(channels(1), :)) / fs;
    components = totalTime / interval;
    alphaBandIndex = calcFreqIndex(alphaBand, f);
    alphaPower(dataset).name = ALLEEG(dataset).setname;
    alphaPower(dataset).meansquare = zeros(32, components, 'single');

    for channel = channels
        for component = 1:components
            first = (component-1)*n + 1;
            last = first + (n-1);
            x = ALLEEG(dataset).data(channel, first:last);
            y = fft(x);
            power = abs(y).^2/n;

            alphaPower(dataset).meansquare(channel, component) = sqrt(mean(power(alphaBandIndex)));
        end
    end
end

figure;
hold on;
for channel = channels
    continuous = [];
    for dataset = datasets
        continuous = horzcat(continuous, alphaPower(dataset).meansquare(channel, :));
    end
    plot(continuous);
end
legend(strsplit(num2str(channels), ' '), 'Location', 'northeast');
xlabel('Time');
ylabel('Power');
