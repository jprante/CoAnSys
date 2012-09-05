/*
 * (C) 2010-2012 ICM UW. All rights reserved.
 */

-- -----------------------------------------------------
-- import section
-- -----------------------------------------------------
register /usr/lib/hbase/lib/zookeeper.jar 
register /usr/lib/hbase/hbase-0.92.1-cdh4.0.1-security.jar 
register /usr/lib/hbase/lib/guava-11.0.2.jar 
register lib/document-classification-1.0-SNAPSHOT-jar-with-dependencies.jar
-- -----------------------------------------------------
-- load HBase rows
-- -----------------------------------------------------
raw = LOAD 'hbase://testProto' 
	  USING org.apache.pig.backend.hadoop.hbase.HBaseStorage('m:mproto','-loadKey true') 
	  AS (id:chararray, proto:bytearray);
-- -----------------------------------------------------
-- protobuff processing: extract docId, title, abstract, kw from DocMetaProto. 
-- -----------------------------------------------------
extracted = FOREACH raw GENERATE 
				FLATTEN(pl.edu.icm.coansys.classification.
				documents.pig.extractors.EXTRACT_KEY_TI_ABS_KW($0,$1));
-- -----------------------------------------------------
-- further processing: 
-- * concatenate ti, abs and kw.
-- * lowercase them, remove diacritics, 
-- * remove non-alphanumerical data, remove stopwords, 
-- * emit key-value pair, K:docId, V:stemmed(word)
-- -----------------------------------------------------
pic = FOREACH extracted GENERATE 
			FLATTEN(pl.edu.icm.coansys.classification.
			documents.pig.proceeders.STEMMED_PAIRS($0,$1,$2,$3)) 
	  		as (key:chararray,word:chararray);
-- -----------------------------------------------------
-- word count
-- -----------------------------------------------------
A1 = group pic by (word, key);
A = foreach A1 generate FLATTEN(group), COUNT(pic) as wc;
-- -----------------------------------------------------
-- doc word count
-- -----------------------------------------------------
B1 = group A by key;
B = foreach B1 generate FLATTEN(A), SUM(A.wc) as wid;
-- -----------------------------------------------------
-- docs count
-- -----------------------------------------------------
C1 = group B by key;
C2 = group C1 all;
C = foreach C2 generate flatten(C1), COUNT(C1) as alldocs;
D = foreach C generate flatten(B), alldocs;
-- -----------------------------------------------------
-- doc per word
-- -----------------------------------------------------
E1 = group D by word;
E = foreach E1 generate flatten(D), COUNT(D) as docperword;
-- -----------------------------------------------------
-- tfidf
-- -----------------------------------------------------
F = foreach E generate flatten(
		pl.edu.icm.coansys.classification.
		documents.pig.proceeders.TFIDF(*))
		as (key:chararray, word:chararray, tfidf:double);
		
/* **************************************************
					BEGIN
	Uncomment following code to use only information
	in the lower triangle of a similarity matrix 
*************************************************** */
/*
	Option A:  create the upper half of a cross product
*/
-- G = group F by key;
-- H = foreach G generate *;
-- CroZ = filter(cross G, H) by G::group < H::group;
/*
	XOR
*/
/*
	Option B:  full data from similarity matrix
*/
G = group F by key;
H = foreach G generate *;
CroZ = filter(cross G, H) by G::group != H::group;
/* **************************************************
					END 
*************************************************** */
-- -----------------------------------------------------
-- measure cosine document similarity
-- -----------------------------------------------------
I = foreach CroZ generate flatten(
		pl.edu.icm.coansys.classification.
		documents.pig.proceeders.DOCSIM(*))
		as (keyA:chararray, keyB:chararray, sim:double);

J = filter I by keyA is not null;

K = group J by keyA;
DESCRIBE K;

STORE J INTO '/tmp/docsim.pigout';