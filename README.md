# SQL Server 2017 Integration Services Cookbook
This is the code repository for [SQL Server 2017 Integration Services Cookbook](https://www.packtpub.com/big-data-and-business-intelligence/sql-server-2017-integration-services-cookbook?utm_source=github&utm_medium=repository&utm_campaign=9781786461827), published by [Packt](https://www.packtpub.com/?utm_source=github). It contains all the supporting project files necessary to work through the book from start to finish.
## About the Book
SQL Server Integration Services is a tool that facilitates data extraction, consolidation, and loading options (ETL), SQL Server coding enhancements, data warehousing, and customizations. With the help of the recipes in this book, you’ll gain complete hands-on experience of SSIS 2017 as well as the 2016 new features, design and development improvements including SCD, Tuning, and Customizations.

At the start, you’ll learn to install and set up SSIS as well other SQL Server resources to make optimal use of this Business Intelligence tools. We’ll begin by taking you through the new features in SSIS 2016/2017 and implementing the necessary features to get a modern scalable ETL solution that fits the modern data warehouse.

Through the course of chapters, you will learn how to design and build SSIS data warehouses packages using SQL Server Data Tools. Additionally, you’ll learn to develop SSIS packages designed to maintain a data warehouse using the Data Flow and other control flow tasks. You’ll also be demonstrated many recipes on cleansing data and how to get the end result after applying different transformations. Some real-world scenarios that you might face are also covered and how to handle various issues that you might face when designing your packages.


## Instructions and Navigation
All of the code is organized into folders. Each folder starts with a number followed by the application name. For example, Chapter02.



The code will look like the following:
```
SELECT ProductID, Name ProductName, ProductNumber, Color, StandardCost,
ListPrice, [Size], Weight, ProductModelID, ProductCategoryID
FROM Staging.StgProduct
WHERE LoadExecutionId = ?
```

This book was written using SQL Server 2016 and all the examples and functions should
work with it. Other tools you may need are Visual Studio 2015, SQL Data Tools 16 or higher
and SQL Server Management Studio 17 or later.
In addition to that, you will need Hortonworks Sandbox Docker for Windows Azure
account and Microsoft Azure.
The last chapter of this book has been written using SQL Server 2017.

## Related Products
* [Microsoft SQL Server 2012 Integration Services: An Expert Cookbook](https://www.packtpub.com/networking-and-servers/microsoft-sql-server-2012-integration-services-expert-cookbook?utm_source=github&utm_medium=repository&utm_campaign=9781849685245)

* [SQL Server 2016 Reporting Services Cookbook](https://www.packtpub.com/big-data-and-business-intelligence/sql-server-2016-reporting-services-cookbook?utm_source=github&utm_medium=repository&utm_campaign=9781786461810)

* [SQL Server Analysis Services 2012 Cube Development Cookbook](https://www.packtpub.com/big-data-and-business-intelligence/sql-server-analysis-services-2012-cube-development-cookbook?utm_source=github&utm_medium=repository&utm_campaign=9781849689809)
### Download a free PDF

 <i>If you have already purchased a print or Kindle version of this book, you can get a DRM-free PDF version at no cost.<br>Simply click on the link to claim your free PDF.</i>
<p align="center"> <a href="https://packt.link/free-ebook/9781786461827">https://packt.link/free-ebook/9781786461827 </a> </p>