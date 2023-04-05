%Written by Michael Griffin 11/6/2016

%Combines data across experiments, then recalculates working memory Z-scores based on new,
%larger groups.

%3/10/2023: Code here was written in Matlab 2012b. In addition to being a long time ago,
%this version of Matlab preceded some more modern conveniences like tables.
%Thus, the data is almost exclusively manipulated as 2d arrays of cells, with workarounds
%for things like selecting the right columns.

pkg load io %in Octave allows xlswrite/xlsread

exps = [1,2,3,4]; %[1,2]	[3,4] 	 1:4
exclude = 0; %Load data where subjects with recall accuracy <= 1 item are cut.
writefile = 1;

for n = exps
    filename = ['data/overallsummary_exp', num2str(n), '.xlsx'];
    if exclude
        [num, ~, raw] = xlsread(filename, 1);
    else
        [num, ~, raw] = xlsread(filename, 2);
    end
    filename = ['data/fullwmsummary_exp', num2str(n), '.xlsx'];
    [numwm, ~, rawwm] = xlsread(filename);
    if exclude
        [~,relevant,~] = intersect(numwm(:,1), num(:,1));
        numwm = numwm(relevant,:);
        rawwm = rawwm([1;relevant+1],:);
    end

    cutoff = find(isnan(num(:,2)), 1, 'first'); %don't need to subtract by 1 because there's labels in raw.
    raw = raw(1:cutoff,:);
    cutoff = raw(1,:);
    cutoff = cutoff(cellfun('isclass', cutoff, 'char'));
    cutoff = length(cutoff); %finds last labeled column by cutting out nonchar cells.
    raw = raw(:,1:cutoff);
    expr = ['exp', int2str(n), 'data = raw;'];
    eval(expr);

    expr = ['wm', int2str(n), 'data = rawwm;'];
    eval(expr);
end

switch exps
	case [1,2]
		wmsummary = [wm1data; wm2data(2:end,:)];
	case [3,4]
		wmsummary = [wm3data; wm4data(2:end,:)];
	case [1:4]
		wmsummary = [wm1data; wm2data(2:end,:); wm3data(2:end,:); wm4data(2:end,:)];
end
wmdata = cell2mat(wmsummary(2:end,:));

for k = 1:length(exps)
	cexp = exps(k);
	expr = ['cdata = exp', int2str(cexp), 'data;'];
	eval(expr);
	if exps(k) == 1
		pointcols = find(ismember(cdata(1,:), [{'Acc 0Points'} {'Acc 3Points'} {'Acc 5Points'}]));
		start = min(pointcols);
		finish = max(pointcols);
		for r = 2:size(cdata,1)
			for c = start:2:finish-1
				cdata{r,c} = mean([cdata{r,c}, cdata{r,c+1}]);
				cdata{r,c+1} = cdata{r,c};
			end
		end
	else
		pointcols = find(ismember(cdata(1,:), [{'Acc 0Points'} {'Acc 5Points'} {'Acc 10Points'}]));
	end
	if exps(k) == 1
		cdata(1,pointcols) = [{'Acc LowPoints'} {'Acc MidPoints'} {'Acc HighPoints'}]; %Relabel
	end
	cdata = cdata(:,[1:min(pointcols)-1, pointcols, max(pointcols)+1:size(cdata,2)]); %should do nothing for exps2-4

	if exps(1) == 1 && cexp >= 3 %cut additional columns
		start = find(ismember(cdata(1,:), 'Acc L1'));
		finish = find(ismember(cdata(1,:), 'AccL5 10Points'));
		cdata = cdata(:,[1:start-1, finish+1:end]);
	end

	%Selectivity is an empty cell when Acc = 0. Set to NaN so averages can be calculated
	for n = 1:size(cdata,2)
		index = find(cellfun('isempty', cdata(:,n)));
		for o = 1:length(index)
			crow = index(o);
			cdata{crow,n} = NaN;
		end
	end


	%concatenate cdata into combsummary.
	if k == 1
		combsummary = cdata;
	else
		combsummary = [combsummary; cdata(2:end,:)];
	end
end


%Calculate new working memory z-scores.
for m = 3:5
	indexes = find(~isnan(wmdata(:,m)));
	averagescore = mean(wmdata(indexes,m));
	stdev = std(wmdata(indexes,m));
	for n = 1:length(indexes)
	   wmdata(indexes(n),m+3) = (wmdata(indexes(n),m) - averagescore)/stdev;
	end
end
for n = 1:length(wmdata)
	cols = find(~isnan(wmdata(n,6:8)))+5; %5 being a column adjust
	wmdata(n,2) = mean(wmdata(n,cols));
end


%Recalculate quartile/median split scores with the new (combined) group.
%Follows same procedure as analysis_summarize
%Col 4: High WM subject	 Col 5: Low WM subject	 Col 6: WM quartile
highlow = zeros(size(wmdata,1), 7);
highlow(:,7) = 1:size(highlow, 1);
highlow(:,1:2) = wmdata(:,1:2);
%highlow(:,3) = recalldata(:,2); %relevant for analysis_summarize, not here.
qsize = floor(size(highlow,1)/4);
highlow = sortrows(highlow,2);
highlow(1:floor(size(highlow,1)/2),4) = 1;
highlow(floor(size(highlow,1)/2)+1:end,5) = 1;
highlow(1:qsize,6) = 1;
highlow(qsize+1:2*qsize,6) = 2;
highlow(2*qsize+1:length(highlow)-qsize,6) = 3;
highlow(length(highlow)-qsize+1:end,6) = 4;

highlow = sortrows(highlow,7);
Labels = [{'Subject'} {'OverallWM'} {'OverallAcc'} {'Low WM'} {'High WM'} {'WM Quartile'}];
formathighlow = [Labels; num2cell(highlow(:,1:6))];

%Getting it back into combined.
start = find(ismember(combsummary(1,:), 'OverallWM'));
for n = 1:length(start)
	combsummary(:,start(n)) = formathighlow(:,2);
end
start = find(ismember(combsummary(1,:), 'Low WM'));
finish = start+2;
combsummary(:,start:finish) = formathighlow(:,4:end);


%Recall data calculations
finish = find(ismember(combsummary(1,:), 'OverallWM'),1)-1; %Start of WM is end of recall
recalldata = cell2mat(combsummary(2:end,1:finish));
rawrecalldata = combsummary(:,1:finish);
averages = zeros(7,size(recalldata,2));
serrors = zeros(7,size(recalldata,2));


for n = 2:size(recalldata,2) %1 being subn
	relevant = recalldata(:,n);
	relevant = relevant(~isnan(relevant));
	averages(1,n) = mean(relevant);
	serrors(1,n) = std(relevant)/sqrt(length(relevant));

	for o = 1:4
		csubs = find(highlow(:,6) == o); %4 being high, 1 being low.
		relevant = recalldata(csubs,n);
		relevant = relevant(~isnan(relevant));
		averages(o+1,n) = mean(relevant);
		serrors(o+1,n) = std(relevant)/sqrt(length(relevant));
	end
	for o = 1:2
		switch o
			case 1
				csubs = find(highlow(:,6) <= 2);
			case 2
				csubs = find(highlow(:,6) >= 3);
		end
		relevant = recalldata(csubs,n);
		relevant = relevant(~isnan(relevant));
		averages(o+5,n) = mean(relevant);
		serrors(o+5,n) = std(relevant)/sqrt(length(relevant));
	end
end


##wcorrelations = zeros(2,2); %Col 1 is unweighted, 2 weighted. Row 1: wm/effic, row 2 wm/acc.
##%Weighted correlations
##relevant = find(recalldata(:,2) ~= 0); %NaN for efficiency messes up weightedcorrs. Given that they'd be weighted as 0, doesn't hurt to remove.
##tocorr = [wmdata(relevant,2), recalldata(relevant,3)]; %wm/effic
##corrmatrix = corr(tocorr);
##wcorrelations(1,1) = corrmatrix(1,2);
##corrmatrix = weightedcorrs(tocorr, recalldata(relevant,2));
##wcorrelations(1,2) = corrmatrix(1,2);
##tocorr = [wmdata(relevant,2), recalldata(relevant,2)]; %wm/recall
##corrmatrix = corr(tocorr);
##wcorrelations(2,1) = corrmatrix(1,2);
##corrmatrix = weightedcorrs(tocorr, recalldata(relevant,2));
##wcorrelations(2,2) = corrmatrix(1,2);
##
##wcorrelations = [{'Unweighted'} {'Weighted'}; num2cell(wcorrelations)];
##Labels = [{'Correlations'}; {'WM and Selec'}; {'WM and Acc'}];
##wcorrelations = [Labels wcorrelations];

##%Sticking in Weighted correlations
##row = size(formatsummary,1)-size(wcorrelations,1)+1:size(formatsummary);
##col = size(averages,2)+2:size(averages,2)+size(wcorrelations,2)+1;
##formatsummary(row,col) = wcorrelations;

formatsummary = cell((size(averages,1)+2)*2,size(combsummary,2)); %Should be 18. size of averages + serrors, and 2 rows of blank space
formatsummary(3:2+size(averages, 1), 1:size(averages,2)) = num2cell(averages);
formatsummary(5+size(serrors, 1):end,1:size(serrors,2)) = num2cell(serrors);


Labels = [{[]}; {[]}; {'Mean: Overall'}; {'Q1 WM'}; {'Q2 WM'}; {'Q3 WM'}; {'Q4 WM'}; {'MedLow WM'}; {'MedHigh WM'}; {[]}; {[]}; ...
	{'S.E. Overall'}; {'S.E. Q1 WM'}; {'S.E. Q2 WM'}; {'S.E. Q3 WM'}; {'S.E. Q4 WM'}; {'S.E. MedLow WM'}; {'S.E. MedHigh WM'}];
formatsummary(:,1) = Labels;
formatsummary(2,2:size(rawrecalldata,2)) = rawrecalldata(1,2:end); %Grabs labels from recall data.
fullsummary = [combsummary; formatsummary];


%2,4,6 or 1,3,5
if writefile
	switch exps
		case [1,2]
			writesheet = 2-exclude;
		case [3,4]
			writesheet = 4-exclude;
		case [1:4]
			writesheet = 6-exclude;
	end
	xlswrite('overallsummary_combined.xlsx', fullsummary, writesheet);
end

