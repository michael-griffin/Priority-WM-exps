%Written by Michael Griffin 4/1/2016

%recall analysis:
%Run if calcrecall = 1. Gets Accuracy and selectivity scores for each subject.
%Writes to fullrecallsummary_exp[n].xlsx

%working memory analysis:
%Run if calcwm = 1. Get scores for each working memory subtest. Calculate
%average/sd, then zscores across subjects for each test. Then calculate
%average z score. Writes to fullwmsummary_exp[n].xlsx

%Combined Analyses:
%Run if calcsupplement = 1. Loads from fullwmsummary and fullrecallsummary files.
%Splits subjects into high/low working memory groups, and calculates descriptive statistics
%(mean, standard error) for working memory and recall. Writes to overallsummary_exp[n].xlsx

%3/10/2023: Code here was written in Matlab 2012b. In addition to being a long time ago,
%this version of Matlab preceded some more modern conveniences like tables.

pkg load io %in Octave, allows xlswrite/xlsread

exp = 1; %Changes subject numbers, data folder.

calcrecall = 1; %writes fullrecallsummary_exp[n].xlsx
calcwm = 0; %writes fullwmsummary_exp[n].xlsx
calcsupplement = 1;	%writes overallsummary_exp[n].xlsx
exclude = 0; %cut subjects where memory during recall was either 0 or only 1 word.
writefile = 0;

folder = ['data/data_exp', num2str(exp), '/'];
folder_matf = [folder, 'mat/'];

allfiles = dir(folder);
relevantnames = struct2cell(allfiles)'(:,1);
tocut = [];
digitpat = '[0-9]{6}'; %look for subject numbers (any digits in a sequence of 6 in a row.)
for n = 1:length(relevantnames)
	[~,~,~,match,~,~,~] = regexp(relevantnames{n,1},digitpat);
	if ~isempty(match)
		relevantnames(n,1) = match;
	else
		tocut = [tocut, n];
	end
end
relevantnames(tocut,:) = [];
subs = char(unique(relevantnames));


if calcrecall
    %Column info for loaded recalldata
    %Col 3: study/test phase
    %Col 6: point values
    %Col 8: recall accuracy
	%For Exp 3-4, Col 3 is list number, and above are shifted over 1 column.

	%Columns for recall summary:
	%subn	overallAcc	Selectivity	PointValueAccs ([0-5] or [0,5,10])
	%For Exp 3-4, also includes by list measures of the above
    if exp == 1
		recallsummary = zeros(length(subs), 9);
		acccol = 8;
        pointscol = 6;
        ideal = sort(repmat([5 4 3 2 1 0], 1, 9), 'descend');
        chance = 2.5; %score one should expect to get due to chance if one ignored point values
    elseif exp == 2
		recallsummary = zeros(length(subs), 6);
		acccol = 8;
        pointscol = 6;
        ideal = sort(repmat([10 5 0], 1, 18), 'descend');
        chance = 5;
    elseif exp == 3 || exp == 4
		recallsummary = zeros(length(subs), 6+5+5+15);
		acccol = 9;
        pointscol = 7;
        ideal = sort(repmat([10 5 0], 1, 35), 'descend');
        ideallist = sort(repmat([10 5 0], 1, 7), 'descend');
        chance = 5;
    end

	recallsummary(:,1) = str2double(subs);


    for n = 1:length(subs)
        subn = subs(n,:);
		filename = ['sub',subn, '_data.mat'];
        load([folder_matf, filename]);
        crecalldata_full = rawdata;
		%no response during recall leaves acc as its initial value NA. Change to 0.
		index = cellfun("ischar",crecalldata_full(:,acccol));
		crecalldata_full(index,acccol) = {0};

        if exp < 3
            start = find(ismember(crecalldata_full(:,3), 'TEST'), 1);
            crecalldata = crecalldata_full(start:end,:);
        else
            indexes = ismember(crecalldata_full(:,4), 'TEST');
            crecalldata = crecalldata_full(indexes,:);
        end

		%Calculate overall measures of Accuracy/Selectivity
        recallpoints = cell2mat(crecalldata(:,pointscol));
        recallacc = cell2mat(crecalldata(:,acccol));

        overallacc = mean(cell2mat(crecalldata(:,acccol)));
        recallsummary(n,2) = overallacc;

        indexes = find(recallacc);
		if length(indexes) > 0
			if length(indexes) == length(recallacc)
				selectivity = 1;
			else
				meanpoints = mean(recallpoints(indexes));
				idealpoints = mean(ideal(1:length(indexes)));
				selectivity = (meanpoints - chance)/(idealpoints - chance);
			end
		else
			selectivity = NaN;
		end
		recallsummary(n,3) = selectivity;


		if exp == 1
			for o = 0:5
				index = find(recallpoints == o);
				recallsummary(n,o+4) = mean(recallacc(index));
			end
		else
			col = 4;
			for o = 0:5:10
				index = find(recallpoints == o);
				recallsummary(n,col) = mean(recallacc(index));
				col = col+1;
			end
		end


		%Calculate by list measures of Accuracy/Selectivity
		if exp == 3 || exp == 4
            numlists = 5;
            blocksize = 21;
            col = 17; %used at the end for acc by point by list columns.
            for m = 1:numlists
                start = 2+blocksize+2*blocksize*(m-1);
                finish = start+blocksize-1;
                crecalldata = crecalldata_full(start:finish,:);

                recallpoints = cell2mat(crecalldata(:,pointscol));
                recallacc = cell2mat(crecalldata(:,acccol));

                overallacc = mean(cell2mat(crecalldata(:,acccol)));
                recallsummary(n,7+m) = overallacc;

                indexes = find(recallacc);
				if length(indexes) > 0
					if length(indexes) == length(recallacc)
						selectivity = 1;
					else
						meanpoints = mean(recallpoints(indexes));
						idealpoints = mean(ideallist(1:length(indexes)));
						selectivity = (meanpoints - chance)/(idealpoints - chance);
					end
				else
					selectivity = NaN;
				end
                recallsummary(n,7+5+m) = selectivity;

                for o = 0:5:10
                    index = find(recallpoints == o);
                    recallsummary(n,col) = mean(recallacc(index));
                    col = col+1;
                end
            end
		end
	end


    if exp == 1
        Labels = [{'Subject'} {'OverallAcc'} {'Selectivity'} ...
            {'Acc 0Points'} {'Acc 1Point'} {'Acc 2Points'} {'Acc 3Points'} {'Acc 4Points'} {'Acc 5Points'}];
    elseif exp == 2
        Labels = [{'Subject'} {'OverallAcc'} {'Selectivity'}...
            {'Acc 0Points'} {'Acc 5Points'} {'Acc 10Points'}];
    elseif exp == 3 || exp == 4
        Labels = [{'Subject'} {'OverallAcc'} {'Selectivity'} {'Acc 0Points'} {'Acc 5Points'} {'Acc 10Points'} ...
            {'Acc L1'} {'Acc L2'} {'Acc L3'} {'Acc L4'} {'Acc L5'} ...
            {'Selec L1'} {'Selec L2'} {'Selec L3'} {'Selec L4'} {'Selec L5'} ...
            {'AccL1 0Points'} {'AccL1 5Points'} {'AccL1 10Points'} {'AccL2 0Points'} {'AccL2 5Points'} {'AccL2 10Points'} ...
            {'AccL3 0Points'} {'AccL3 5Points'} {'AccL3 10Points'} {'AccL4 0Points'} {'AccL4 5Points'} {'AccL4 10Points'} ...
            {'AccL5 0Points'} {'AccL5 5Points'} {'AccL5 10Points'}];
    end

    recallsummary = num2cell(recallsummary);
    recallsummary = [Labels; recallsummary];

    if writefile
		summaryname = ['fullrecallsummary_exp', num2str(exp), '.xlsx'];
        xlswrite(['data/', summaryname], recallsummary);
    end
end



if calcwm
    ospanscores = zeros(length(subs), 4); %First col subn, 2nd score, 3rd z score, 4th raw score
    ospanscores(:,1) = str2double(subs);
	rspanscores = ospanscores;
	sspanscores = ospanscores;

    for m = 1:3
        switch m
            case 1
                cscores = ospanscores;
                start = 22; %first nonpractice trial
            case 2
                cscores = rspanscores;
                start = 21;
            case 3
                cscores = sspanscores;
                start = 18;
        end


		for k = 1:length(subs)
			subn = subs(k,:);
			switch m
				case 1
					filename = ['ospan', subn, '.mat'];
				case 2
					filename = ['rspan', subn, '.mat'];
				case 3
					filename = ['sspan', subn, '.mat'];
			end
			load([folder_matf, filename]);
			cdata_full = rawdata;
			cdata = cdata_full(start:end,:);

			%Column Info for Span Tasks
			%Col 2: block num
			%Col 3: block size

			%Accuracy columns differ by task:
			%OPERATION SPAN
			%Col 14: math accuracy			%Col 18: target (letter) accuracy
			%%%READING SPAN
			%Col 8: sentence accuracy		%Col 12: target (letter) accuracy
			%%%%SYMMETRY SPAN
			%Col 8: symmetry accuracy		%Col 12: target (grid) accuracy
			switch m
				case 1
					acccol = find(ismember(cdata_full(1,:), 'RECALLED')); %18
				case 2
					acccol = find(ismember(cdata_full(1,:), 'RECALLED')); %12
				case 3
					acccol = find(ismember(cdata_full(1,:), 'Acc')); %12
			end

			%To more easily get accuracy by block, reconstruct blocks
			index = 1;
			blocks = [];
			indexes = [];
			while index < length(cdata)
				cblock = cdata{index,3};
				blocks = [blocks cblock];
				indexes = [indexes index];
				index = index+cblock;
			end

			%Get score for task. Each block worth up to 1 if 100% accurate.
			rawscore = 0;
			score = 0;
			for o = 1:length(blocks)
				cblock = blocks(o);
				cindex = indexes(o);
				cscore = 0;
				for p = cindex:cindex+cblock-1
					if cdata{p,acccol}
						cscore = cscore + 1;
					end
				end
				rawscore = rawscore + cscore;
				cscore = cscore/cblock;
				score = score + cscore;
			end
			cscores(k,2) = score;
			cscores(k,4) = rawscore;
			end
		end


        %Calculating z scores
        averagescore = mean(cscores(:,2));
        stdev = std(cscores(:,2));
        for k = 1:length(cscores);
            cscores(k,3) = (cscores(k,2) - averagescore)/stdev;
        end

        switch m
            case 1
                ospanscores = cscores;
            case 2
                rspanscores = cscores;
            case 3
                sspanscores = cscores;
        end
    end


    %%%Combining scores
    allscores = zeros(length(subs), 11);
    for n = 1:length(subs)
        allscores(n,1) = str2double(subs(n,:));
    end


    rspanindex = 1;
    ospanindex = 1;
    sspanindex = 1;
    for k = 1:length(allscores);
        numtests = 0;
        total = 0;
        if allscores(k) == sspanscores(sspanindex,1);
            allscores(k,3) = sspanscores(sspanindex,2);
            allscores(k,6) = sspanscores(sspanindex,3);
            allscores(k,9) = sspanscores(sspanindex,4);
            total = total + sspanscores(sspanindex,3);
            if sspanindex < size(sspanscores,1)
                sspanindex = sspanindex + 1;
            end
            numtests = numtests + 1;

        end
        rspanscore = 0;
        if allscores(k) == rspanscores(rspanindex,1);
            allscores(k,4) = rspanscores(rspanindex,2);
            allscores(k,7) = rspanscores(rspanindex,3);
            allscores(k,10) = rspanscores(rspanindex,4);
            total = total + rspanscores(rspanindex,3);
            if rspanindex < size(rspanscores,1)
                rspanindex = rspanindex + 1;
            end
            numtests = numtests + 1;
        end
        ospanscore = 0;
        if allscores(k) == ospanscores(ospanindex,1);
            allscores(k,5) = ospanscores(ospanindex,2);
            allscores(k,8) = ospanscores(ospanindex,3);
            allscores(k,11) = ospanscores(ospanindex,4);
            total = total + ospanscores(ospanindex,3);
            if ospanindex < size(ospanscores,1)
                ospanindex = ospanindex + 1;
            end
            numtests = numtests + 1;
        end

        allscores(k,2) = total/numtests;
    end


    Labels = [{'Subject'} {'OverallWM'}  {'sspan score'}  {'rspan score'} {'ospan score'}...
        {'sspan zscore'} {'rspan_zscore'} {'ospan zscore'} {'sspan raw score'} {'rspan raw score'} {'ospan raw score'}  ];


    allscoresnan = allscores;
    allscores = num2cell(allscores);
    allscores = [Labels; allscores];

    for k = 1:size(allscoresnan, 1)
        for o = 2:size(allscoresnan, 2) %First column is subjects, doesn't need to be checked.
            if allscoresnan(k,o) == 0
                allscoresnan(k,o) = NaN;
            end
        end
    end
    allscoresnan = num2cell(allscoresnan);
    allscoresnan = [Labels; allscoresnan];

    summaryname = ['fullwmsummary_exp', num2str(exp), '.xlsx'];
    if writefile
        xlswrite(['data/', summaryname], allscoresnan);
    end
end


%Split working memory into high/low groups for figures and calculate some simple
%summary measures (mean, standard error)
if calcsupplement
    [wmdata, ~, rawwmdata] = xlsread(['data/fullwmsummary_exp', num2str(exp), '.xlsx']); %should be identical to allscoresnan
    [recalldata, ~, rawrecalldata] = xlsread(['data/fullrecallsummary_exp' num2str(exp), '.xlsx']); %Should be identical to recallsummary
    if exclude
        %cut subjects where memory during recall was either 0 or only 1 word.
        if exp == 1 || exp == 2
            toremove = find(recalldata(:,2) < (1/54 + .001));
        elseif exp == 3 || exp == 4
            toremove = find(recalldata(:,2) < (5/105 + .001));
            for n = 8:12 %list by list accuracy. If any lists' accuracy is 0, exclude.
                toremove = [toremove; find(recalldata(:,n) == 0)];
            end
            toremove = unique(toremove);
        end

        wmdata(toremove,:) = [];
        recalldata(toremove,:) = [];
        rawwmdata(toremove+1,:) = [];
        rawrecalldata(toremove+1,:) = [];
    end

	%Col 4: High WM subject	 Col 5: Low WM subject	 Col 6: WM quartile
    highlow = zeros(size(wmdata,1), 7);
    highlow(:,7) = 1:size(highlow, 1);
    highlow(:,1:2) = wmdata(:,1:2);
    highlow(:,3) = recalldata(:,2);
    qsize = floor(size(highlow,1)/4);
    highlow = sortrows(highlow,2);
    highlow(1:floor(size(highlow,1)/2),4) = 1;
    highlow(floor(size(highlow,1)/2)+1:end,5) = 1;
    highlow(1:qsize,6) = 1;
    highlow(qsize+1:2*qsize,6) = 2;
    highlow(2*qsize+1:length(highlow)-qsize,6) = 3;
    highlow(length(highlow)-qsize+1:end,6) = 4;




    highlow = sortrows(highlow,7);
    lowsubs = find(highlow(:,4) == 1);
    highsubs = find(highlow(:,5) == 1);
    Labels = [{'Subject'} {'OverallWM'} {'OverallAcc'} {'Low WM'} {'High WM'} {'WM Quartile'}];
    formathighlow = [Labels; num2cell(highlow(:,1:6))];


    averages = zeros(7,size(recalldata,2));
    serrors = zeros(7,size(recalldata,2));

    for n = 2:size(recalldata,2) %1 being subn;
        %Trimming NaN entries. Happens to the selectivity column when recallacc was 0.
        relevant = recalldata(:,n);
        relevant = relevant(~isnan(relevant));
        averages(1,n) = mean(relevant);
        serrors(1,n) = std(relevant)/sqrt(length(relevant));

        for o = 1:4
            subs = find(highlow(:,6) == o); %4 being high, 1 being low.
            relevant = recalldata(subs,n);
            relevant = relevant(~isnan(relevant));
            averages(o+1,n) = mean(relevant);
            serrors(o+1,n) = std(relevant)/sqrt(length(relevant));
        end
        for o = 1:2
            switch o
                case 1 %low subs
                    subs = find(highlow(:,6) <= 2);
                case 2 %high subs
                    subs = find(highlow(:,6) >= 3);
            end
            relevant = recalldata(subs,n);
            relevant = relevant(~isnan(relevant));
            averages(o+5,n) = mean(relevant);
            serrors(o+5,n) = std(relevant)/sqrt(length(relevant));
        end
    end



	fullsummary = [rawrecalldata(:,:), rawwmdata(:,2), formathighlow(:,4:end), ...
					rawwmdata(:,2), rawrecalldata(:,2:3)];


    formatsummary = cell((size(averages,1)+2)*2,size(fullsummary,2)); %Should be 18. size of averages + serrors, and 2 rows of blank space
    formatsummary(3:2+size(averages, 1), 1:size(averages,2)) = num2cell(averages);
    formatsummary(5+size(serrors, 1):end,1:size(serrors,2)) = num2cell(serrors);

    Labels = [{[]}; {[]}; {'Mean: Overall'}; {'Q1 WM'}; {'Q2 WM'}; {'Q3 WM'}; {'Q4 WM'}; {'Low WM'}; {'High WM'}; {[]}; {[]}; ...
        {'S.E. Overall'}; {'S.E. Q1 WM'}; {'S.E. Q2 WM'}; {'S.E. Q3 WM'}; {'S.E. Q4 WM'}; {'S.E. Low WM'}; {'S.E. High WM'}];
    formatsummary(:,1) = Labels;
    formatsummary(2,2:size(rawrecalldata,2)) = rawrecalldata(1,2:end); %Grabs labels from recall data.
    fullsummary = [fullsummary; formatsummary];


    summaryname = ['overallsummary_exp', int2str(exp), '.xlsx'];
    if writefile
		xlswrite(['data/', summaryname],fullsummary,2-exclude);
    end
end
