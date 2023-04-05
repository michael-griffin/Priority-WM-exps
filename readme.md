## Repository for the data and analyses presented in:
### Griffin, M. L., Benjamin, A. S., Sahakyan, L., & Stanley, S. E. (2019). A matter of priorities: High working memory enables (slightly) superior value-directed remembering. Journal of Memory and Language, 108. https://doi.org/10.1016/j.jml.2019.104032

---  

**Summary**  
In this experiment, subjects completed a series of working memory tests, followed by a value-directed memory task – a recall test where words are worth varying point values. We were curious as to whether high working memory subjects could more reliably prioritize: focusing study on the high value words and ignore 0 point distractions. They could, but this effect was modest, and suggests better strategies at study may be insufficient to explain the more general advantage seen in recall for those with higher working memory.

**Organization - Folders**  
- data/ Data files for each subject and summary files by experiment
- exp files/ (no longer supported) Actionscript/.fla files 
- figures/ Figures found within the paper

**Organization - Code**  
- Preprocessing
    - **convert_txtfiles.m** *takes raw data and saves as either .xlsx or .mat files.*
	- **analysis_summarize.m** *takes .mat files made in convert_txtfiles and creates working memory, recall, and combined summary files for each experiment.*
	- **analysis_combine.m** *takes summary files above and merges across experiments (1+2, 3+4, and all 4 together)*
- Analysis
    - **analysis_summarize_splithalf.m**	*calculates split-half reliability measures for working memory tests, accuracy, and selectivity*
    - **analysis_correlations.m**	*finds correlations between working memory, recall, and selectivity*
    - **R_bayesfactor.R** 	*finds bayes factors for correlations*


