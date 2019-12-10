% Plot the time variation of alpha wave power

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
    alphaPower(dataset).data = zeros(32, components, 'single');

    for channel = channels
        for index = 1:components
            last = index * n;
            first = last - (n-1);
            x = ALLEEG(dataset).data(channel, first:last);
            y = fft(x);
            power = abs(y).^2/n;

            alphaPower(dataset).data(channel, index) = sqrt(mean(power(alphaBandIndex)));
        end
    end
end

figure;
hold on;
for channel = channels
    continuous = [];
    for dataset = datasets
        continuous = horzcat(continuous, alphaPower(dataset).data(channel, :));
    end
    plot(continuous);
end
legend(strsplit(num2str(channels), ' '), 'Location', 'northeast');
xlabel('Time');
ylabel('Power');
