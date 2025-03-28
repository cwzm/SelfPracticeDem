%% 输入参数
if ~exist('par','var'), par = []; end
if isempty(par),        par = struct; end
if ~isreal(spec)
    warning('~isreal(spec): taking abs'); 
end


%% 频率轴生成
[n1,n2,n3]=size(spec);
if isfield(par,'sample_frequency')
    hz = (-n2/2:n2/2-1)/n2*par.sample_frequency;
    ylstr = 'spec [Hz]';    
else
    hz = (-n2/2:n2/2-1);
    ylstr = 'spec [pts]';
end


%% 绘制原始stack图像
    figure
for l3=1:n3
    if n3>1
        figure(100+l3);
    else
        clf
    end
    x = repmat(hz,[n1 1]).';
    z = repmat((1:n1).',[1 n2]).';
    plot3(z,x,spec(:,:,l3).');
    axis tight
    view(-87,21);
    ylabel(ylstr);

    t_str = sprintf('n1=%g  n2=%g',n1,n2);
    if n3>1, t_str = sprintf('%s   l3=%g',t_str,l3); end
    title(t_str);
    
    if n3>1, set(gcf,'name',sprintf('Slice%d',l3)); end
    grid on
end


%% 绘制总和谱线图像
    sum_spec = sum(spec, 1);  % 计算总和信号谱线
    figure
    plot_complex(sum_spec)


%% 自动优化：总和虚部最小积分
    % 目标函数（使用加权积分）
    w = 1 ./ (1 + abs(hz)); % 权重函数
    objective = @(phases) sum(w .* abs(imag(sum_spec .* exp(-1i * (phases(1) + phases(2) * hz)))));


    % 先用遗传算法大范围搜索
    options_ga = optimoptions('ga', 'PopulationSize', 50, 'MaxGenerations', 50, 'Display', 'iter');
    best_phases_ga = ga(objective, 2, [], [], [], [], [-pi, -1], [pi, 1], [], options_ga);


    % 再用梯度优化精修
    options_fminunc = optimoptions('fminunc', 'Algorithm', 'quasi-newton', 'Display', 'iter');
    best_phases = fminunc(objective, best_phases_ga, options_fminunc);


    % 计算优化后的谱线
    phi0_opt = best_phases(1);
    phi1_opt = best_phases(2);
    sum_spec_opt = sum_spec .* exp(-1i * (phi0_opt + phi1_opt * hz));


    % 显示优化参数
    fig_result = uifigure('Name', 'Optimization Results', 'Position', [100, 100, 300, 200]);
    uilabel(fig_result, 'Text', sprintf('φ₀ = %.4f rad', phi0_opt), 'Position', [50, 120, 200, 30]);
    uilabel(fig_result, 'Text', sprintf('φ₁ = %.4f rad/Hz', phi1_opt), 'Position', [50, 80, 200, 30]);

    %绘制对比图
    figure
    plot(hz, real(sum_spec), 'b--', 'LineWidth', 1);  % 蓝色虚线
    hold on;
    plot(hz, imag(sum_spec), 'g--', 'LineWidth', 1);  % 绿色虚线
    hold on; 
    plot(hz, real(sum_spec_opt), 'b-', 'LineWidth', 1);  % 蓝色实线
    hold on; 
    plot(hz, imag(sum_spec_opt), 'g-', 'LineWidth', 1);  % 绿色实线
    hold off; 

    xlabel('spec [Hz]');
    title('phase Comparison');
    legend('RawReal', 'RawImag', 'CorrReal', 'CorrImag' ); % 添加图例
grid on;


%%计算校正后动态谱
  phase_correction = exp(-1i * (phi0_opt + phi1_opt * hz)); %计算相位修正因子
  spec_corrected = spec .* phase_correction; %应用到所有时间点的谱线


%%绘制校正后动态谱线
 figure
for l3=1:n3
    if n3>1
        figure(100+l3);
    else
        clf
    end
    x = repmat(hz,[n1 1]).';
    z = repmat((1:n1).',[1 n2]).';
    plot3(z,x,spec_corrected(:,:,l3).');
    axis tight
    view(-87,21);
    ylabel(ylstr);

    t_str = sprintf('n1=%g  n2=%g',n1,n2);
    if n3>1, t_str = sprintf('%s   l3=%g',t_str,l3); end
    title(t_str);
    
    if n3>1, set(gcf,'name',sprintf('Slice%d',l3)); end
    grid on
end


%%峰计算

% 设定参数
[n1, n2, n3, n4] = size(ss);  % 获取 CSI 数据维度
slice_index = round(n4 / 2);  % 选择中间切片

% 初始化峰积分数据
peak_integrals = {}; % 使用 cell 数组存储不同峰的积分矩阵
peak_count = 0; % 记录实际检测到的峰数

% 遍历每个体素并计算峰积分
for x = 1:n2
    for y = 1:n3
        spectrum = squeeze(ss(:, x, y, slice_index)); % 获取该体素的谱线
        
        % 识别谱峰（调整参数提高检测能力）
        [pks, locs, widths] = findpeaks(spectrum, 'MinPeakProminence', 0.05, 'MinPeakHeight', max(spectrum)*0.1);
        
        % 显示峰信息
        fprintf('Voxel (%d, %d): Found %d peaks\n', x, y, length(pks));
        for i = 1:length(pks)
            fprintf('   Peak %d: Location = %.3f ppm, Width = %.3f\n', i, locs(i), widths(i));
        end
        
        % 记录峰的积分
        for i = 1:length(pks)
            if length(peak_integrals) < i
                peak_integrals{i} = zeros(n2, n3); % 初始化新的峰积分矩阵
                peak_count = peak_count + 1;
            end
            peak_integrals{i}(x, y) = sum(widths(i) * pks(i)); % 计算峰积分
        end
    end
end

% 绘制峰的积分分布（灰度图）
for i = 1:peak_count
    if max(peak_integrals{i}(:)) > 0  % 仅绘制非空峰图
        figure;
        imagesc(peak_integrals{i}); % 颜色填充
        colormap(gray); % 采用灰度映射
        colorbar; % 添加颜色条
        title(sprintf('Peak %d Integral Map', i));
        xlabel('X Axis (Voxel)');
        ylabel('Y Axis (Voxel)');
    end
end


%%位置标注

% 计算总谱线信号
total_spectrum = sum(sum(sum(ss, 2), 3), 4);

% 设定 ppm 轴（假设从 i 到 j ppm）
ppm_axis = linspace(-176, -166, length(total_spectrum));

% 平滑总谱线以减少噪声影响
smoothed_spectrum = movmean(total_spectrum, 3); % 3 点滑动平均

% 识别峰位置
peak_mask = islocalmax(smoothed_spectrum, 'MinProminence', 0.02); 
peak_indices = find(peak_mask);

% 绘制总谱线
figure;
plot(ppm_axis, total_spectrum, 'b', 'LineWidth', 1.5);
hold on;

% 标注峰位置（黑色虚线）
for i = 1:length(peak_indices)
    xline(ppm_axis(peak_indices(i)), '--k', 'LineWidth', 1.2);
end

% 图像美化
title('Total Spectrum with Peak Positions');
xlabel('Chemical Shift (ppm)');
ylabel('Signal Intensity');
set(gca, 'XDir', 'reverse'); % ppm 轴通常是反向的
hold off;
