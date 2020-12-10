# analytics-stack
This is a parking lot for code used in a hobby-only setup of ClearLinux OS on bare metal. Nothing useful for production here.

The use case is to setup a home lab, which runs a YARN managed Hadoop/HDFS/Spark cluster accessed through Zeppelin/Rstudio. All software used will be open-source. Hardware is whatever I had laying around, or get cheap.

## Home Lab Hardware Setup
1. 1 Laptop; upgraded to 32 GB RAM, 1 TB NVME + 120 GB SSD (Lenovo 81MU007NUS Ideapad S145 14.0" HD Pentium 5405U 2.3GHz)
2. 10 SBCs with 8 GB RAM, 128 SSD https://ark.intel.com/content/www/us/en/ark/products/87740/intel-nuc-kit-nuc5ppyh.html
3. 1 GPU node; a recycled GIGABYTE GAH110D3A LGA 1151 Intel Motherboard with 5 NVIDIA Tesla K20x co-processors

## Sources of Inspiration
1. Anchormen: https://anchormen.nl/blog/big-data-services/spark-and-hdfs-with-kubernetes/
2. The Deployment Bunny: https://deploymentbunny.com/2014/09/28/building-next-gen-datacenter-the-pelicase-portable-datacenter/
3. Reddit: https://www.reddit.com/r/NUCLabs/comments/drblg9/sell_me_on_a_nuc_labcluster/
4. Louis Aslett's Amazon Machine Images: https://www.louisaslett.com/RStudio_AMI/
5. Google v. Oracle America: https://www.scotusblog.com/case-files/cases/google-llc-v-oracle-america-inc/
6. Frank Pasquale's Data-Informed Duties in AI Development: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3503121

## Bench References
1. Ubuntu Unleashed 2019 Edition; Matthew Helmke
2. Deep Learning with R for Beginners; Hodnett, Wiley et. al.
3. Machine Learning with R; Brett Lantz
4. Mastering Spark with R; Luraschi, Kuo et. al.
5. Web Application Development with R Using Shiny; Chris Beeley
6. R Markdown; Xie, Allaire, et. al.
7. Docker Deep Dive; Nigel Poulton
8. The Kubernetes Book; Nigel Poulton
9. Spark: The Definitive Guide; Bill Chambers and Matel Zaharia
10. Hadoop: The Definitive Guide; Tom White
