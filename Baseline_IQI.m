%Evaluate IQ Imbalance (IQI) On System Performance 
clear all; clc; close all; 

%Step 1.a: Parameter Settings
mod_schemes = {'BPSK', 'QPSK', '8PSK', 'QAM'};  %modulation schemes
mod_orders = [2, 4, 8, 4];      % Mod orders     
numSC = 128;           % Number of OFDM subcarriers
cpLen = 32;            % OFDM cyclic prefix length
maxNumBits = 1e6;      % Maximum number of bits transmitted
errorRate = comm.ErrorRate('ResetInputPort',true);
EbNo = (-5:10)';                           %EbNo values 
ampImb_vec = [0.05, 0.1];                        % IQI ampImb (dB)
phImb_vec = [12,18];                          % IQI phImb (deg)

%intialize vectors for storing current BER
berVecAllModSchemes = zeros(length(mod_schemes), length(EbNo));

%Step 1.b: Loop Through All Modulation Schemes & Loop Through IQI Alpha and Beta Values
for i = 1:length(ampImb_vec)
    ampImb = ampImb_vec(i); 
    phImb = phImb_vec(i); 
    for mod = 1:length(mod_schemes)
        disp(mod_schemes(mod))
        M = mod_orders(mod); 
        k = log2(M); %get bit/symbol
        berVec = zeros(1, length(EbNo)); %initialize BER vector 
        errorStats = zeros(1,3); %R = BER, N=#errors, S = #samples compared
        
        %Step 2: Initialize OFDM Modulator and Demodulator
        ofdmMod = comm.OFDMModulator('FFTLength',numSC,'CyclicPrefixLength',cpLen);
        ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen);
        
        ofdmDims = info(ofdmMod); 
        numDC = ofdmDims.DataInputSize(1); %num data subcarriers 
        snrVec = EbNo + 10*log10(k) + 10*log10(numDC/numSC); %convert EbNo to SNR
        frameSize = [k*numDC ,1]; %set frame size
        
        %Step 3: Create AWGN Channel 
        channel = comm.AWGNChannel('NoiseMethod','Variance', ...
            'VarianceSource','Input port');
    
        %Step 4: Loop Through EbNo Values 
        for m = 1:length(EbNo)
            disp(EbNo(m))
            snr = snrVec(m);
            
            while errorStats(3) <= maxNumBits
                data = randi([0,1],frameSize);                            % Generate binary data
                if ~strcmp(mod_schemes(mod), 'qam')
                    data_mod = pskmod(data, M, pi/M, InputType="bit");    % Apply M-PSK modulation
                else
                    data_mod = qammod(data, M, InputType="bit");
                end 
              
                txSig = ofdmMod(data_mod);                    % Apply OFDM modulation
        
                powerDB = 10*log10(var(txSig));               % Calculate Tx signal power
                noiseVar = 10.^(0.1*(powerDB-snr));           % Calculate the noise variance
    
                rxSig = iqimbal(txSig,ampImb,phImb);          % Add IQ Imbalance 
                rxSig = channel(rxSig,noiseVar);              % Pass the signal through a noisy channel
                rxSig = ofdmDemod(rxSig);                    % Apply OFDM demodulation

                if ~strcmp(mod_schemes(mod), 'qam')
                    dataOut = pskdemod(rxSig, M, pi/M, 'OutputType','bit'); % Apply M-PSK de-modulation
                else
                    dataOut = qamdemod(rxSig, M, 'OutputType', 'bit'); %Apply QAM de-modulation
                end

                errorStats = errorRate(data,dataOut,0);     % Collect error statistics
            end
            
            berVec(m) = errorStats(1);                      % Save BER data
            errorStats = errorRate(data,dataOut,1);         % Reset the error rate calculator
        end

    %store BER for mod scheme
    berVecAllModSchemes(mod, :) = berVec; 
    
    end 
    %store BER for current ampImb and phImb configuration
    %columns = snr, rows = mod scheme (BPSK, QPSK, 8PSK, QAM)
    writematrix(berVecAllModSchemes, 'IQI Imbalance Baseline.xls', 'Sheet', i);
end 

%% Step 5: Plot Error Curve vs. AWGN Baseline

%load AWGN Baseline 
awgn_baseline = readmatrix('AWGN Baseline.xls'); 

%alpha = 0.05, beta = 12
IQI_baseline = readmatrix('IQI Imbalance Baseline.xls', 'Sheet', 'Sheet1'); 

figure
tiledlayout(2,2, 'TileSpacing', 'tight')

nexttile
semilogy(EbNo, IQI_baseline(1,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(1,1:16), '-o')
title('BPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(2,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(2, 1:16), '-o')
title('QPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(3,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(3, 1:16), '-o')
title('8-PSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(4,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(4, 1:16), '-o')
title('QAM')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

lg = legend('AWGN Only', 'AWGN & IQI'); 
lg.Orientation = 'horizontal';
lg.Layout.Tile = 'south';


sgtitle(sprintf('IQ Imbalance, alpha = %0.2f beta=%0.2f', [ampImb_vec(1), phImb_vec(1)]))

saveas(gcf, 'IQI Imbal v1.m')

%% alpha = 0.1 beta=18
IQI_baseline = readmatrix('IQI Imbalance Baseline.xls', 'Sheet', 'Sheet2'); 

figure
tiledlayout(2,2, 'TileSpacing', 'tight')

nexttile
semilogy(EbNo, IQI_baseline(1,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(1, 1:16), '-o')
title('BER AWGN Channel BPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(2,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(2, 1:16), '-o')
title('BER AWGN Channel QPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(3, :),'-*')
hold on
semilogy(EbNo, awgn_baseline(3, 1:16), '-o')
title('BER AWGN Channel 8-PSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo, IQI_baseline(4,:),'-*')
hold on
semilogy(EbNo, awgn_baseline(4, 1:16), '-o')
title('BER AWGN Channel QAM')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

lg = legend('AWGN Only', 'AWGN & IQI'); 
lg.Orientation = 'horizontal';
lg.Layout.Tile = 'south';

sgtitle(sprintf('IQ Imbalance alpha = %0.2f and beta = %0.2f', [ampImb_vec(2), phImb_vec(2)]))

saveas(gcf, 'IQI Imbal v2.m')