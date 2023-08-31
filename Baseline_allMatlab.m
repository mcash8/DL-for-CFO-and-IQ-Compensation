%OFDM Baseline using all Matlab System Objects [https://www.mathworks.com/help/comm/gs/qpsk-and-ofdm-with-matlab-system-objects-1.html]
clear all; clc; 

%Step 1: Parameter Settings and Error Rate Object 
%M = [2, 4, 8];                     % Modulation alphabet
M = 4;
k = log2(M);           % Bits/symbol
mod_schemes = {'BPSK', 'QPSK', '8PSk', 'QAM'};  %modulation schemes
numSC = 128;           % Number of OFDM subcarriers
cpLen = 32;            % OFDM cyclic prefix length
maxBitErrors = 100;    % Maximum number of bit errors
maxNumBits = 1e7;      % Maximum number of bits transmitted
errorRate = comm.ErrorRate('ResetInputPort',true);


%Step 2: Set OFDM Modulator and Demodulator
ofdmMod = comm.OFDMModulator('FFTLength',numSC,'CyclicPrefixLength',cpLen);
ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen);

ofdmDims = info(ofdmMod); 
numDC = ofdmDims.DataInputSize(1); %num data subcarriers 
frameSize = [k*numDC ,1];

%Step 3: Create AWGN Channel 
channel = comm.AWGNChannel('NoiseMethod','Variance', ...
    'VarianceSource','Input port');

EbNo = (0:10)';
snrVec = EbNo + 10*log10(k) + 10*log10(numDC/numSC); %convert EbNo to SNR
berVec = zeros(length(EbNo),3);
errorStats = zeros(1,3); %R = BER, N=#errors, S = #samples compared

%Step 4:  Loop Through All EbNo Values -- To Do, add diff mod schemes 

for m = 1:length(EbNo)
    snr = snrVec(m);
    disp(snr)
    while errorStats(2) <= maxBitErrors && errorStats(3) <= maxNumBits
        data = randi([0,1],frameSize);              % Generate binary data
        qpskTx = pskmod(data, M, pi/M, InputType="bit");      % Apply QPSK modulation
       
        txSig = ofdmMod(qpskTx);                      % Apply OFDM modulation
        powerDB = 10*log10(var(txSig));           % Calculate Tx signal power
        noiseVar = 10.^(0.1*(powerDB-snr));           % Calculate the noise variance

        rxSig = channel(txSig,noiseVar);              % Pass the signal through a noisy channel
        qpskRx = ofdmDemod(rxSig);                    % Apply OFDM demodulation
        dataOut = pskdemod(qpskRx, M, pi/M, OutputType="bit");                  % Apply QPSK demodulation
        errorStats = errorRate(data,dataOut,0);     % Collect error statistics
    end
    
    berVec(m,:) = errorStats;                         % Save BER data
    errorStats = errorRate(data,dataOut,1);         % Reset the error rate calculator
end


%Step 5: Plot Error Curve
berTheory = berawgn(EbNoVec,'psk',M,'nondiff');

figure
semilogy(EbNo,berVec(:,1),'*')
hold on
semilogy(EbNo,berTheory)
legend('Simulation','Theory','Location','Best')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on
hold off
