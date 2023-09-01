%OFDM Baseline using all Matlab System Objects [https://www.mathworks.com/help/comm/gs/qpsk-and-ofdm-with-matlab-system-objects-1.html]
clear all; clc; close all;  

%Step 1.a: Parameter Settings and Error Rate Object 
mod_schemes = {'BPSK', 'QPSK', '8PSK', 'QAM'};  %modulation schemes
mod_orders = [2, 4, 8, 4];      % Mod orders     
numSC = 128;           % Number of OFDM subcarriers
cpLen = 32;            % OFDM cyclic prefix length
maxNumBits = 1e6;      % Maximum number of bits transmitted
errorRate = comm.ErrorRate('ResetInputPort',true);
EbNo = (0:10)'; %EbNo values 
berVecAllModSchemes = zeros(length(mod_schemes), length(EbNo));

%Step 1.b: Loop Through All Modulation Schemes
for mod = 1:length(mod_schemes)
    %intialize vectors for storing BER
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
    
    %Step 4:  Loop Through All EbNo Values -- To Do, add diff mod schemes 
    
    for m = 1:length(EbNo)
        disp(EbNo(m))
        snr = snrVec(m);
        
        while errorStats(3) <= maxNumBits
            data = randi([0,1],frameSize);                          % Generate binary data
            qpskTx = pskmod(data, M, pi/M, InputType="bit");      % Apply QPSK modulation
           
            txSig = ofdmMod(qpskTx);                      % Apply OFDM modulation
            powerDB = 10*log10(var(txSig));           % Calculate Tx signal power
            noiseVar = 10.^(0.1*(powerDB-snr));           % Calculate the noise variance
    
            rxSig = channel(txSig,noiseVar);              % Pass the signal through a noisy channel
            qpskRx = ofdmDemod(rxSig);                    % Apply OFDM demodulation
            dataOut = pskdemod(qpskRx, M, pi/M, OutputType="bit");                  % Apply QPSK demodulation
            errorStats = errorRate(data,dataOut,0);     % Collect error statistics
        end
        
        berVec(m) = errorStats(1);                         % Save BER data
        errorStats = errorRate(data,dataOut,1);         % Reset the error rate calculator
    end
    %store BER for mod scheme
    berVecAllModSchemes(mod, :) = berVec; 
end 

%%
%Step 5: Plot Error Curve
berTheory_bpsk = berawgn(EbNo,'psk',2,'nondiff');
berTheory_qpsk = berawgn(EbNo,'psk',4,'nondiff');
berTheory_8psk = berawgn(EbNo,'psk',8,'nondiff');
berTheory_qam = berawgn(EbNo,'qam',4,'nondiff');


figure
tiledlayout(2,2, 'TileSpacing', 'loose')

nexttile
semilogy(EbNo,berVecAllModSchemes(1,:),'-o')
hold on
semilogy(EbNo,berTheory_bpsk)
title('BER AWGN Channel BPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo,berVecAllModSchemes(2,:),'-o')
hold on
semilogy(EbNo,berTheory_qpsk)
title('BER AWGN Channel QPSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo,berVecAllModSchemes(3,:),'-o')
hold on
semilogy(EbNo,berTheory_8psk)
title('BER AWGN Channel 8PSK')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off

nexttile
semilogy(EbNo,berVecAllModSchemes(2,:),'-o')
hold on
semilogy(EbNo,berTheory_qam)
title('BER AWGN Channel QAM')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate') 
grid on
hold off

lg = legend('Simulation', 'Theory'); 
lg.Orientation = 'horizontal';
lg.Layout.Tile = 'south';

saveas(gcf, 'AWGN Baseline.png')