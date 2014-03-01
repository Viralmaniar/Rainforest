#!/usr/bin/env ruby1.8
# encoding: utf-8

srequire 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'rubygems'
require 'sqlite3'
require 'csv'






#define constants 
#variable Name & Value
CeReservedMask=0x4C000000
CeLocationSelectorMask=0x30000000
CeLocationSelectorOffset=28
CeExtraBlocksMask=0x03000000
CeExtraBlocksOffset=24
CeBlockNumberMask=0x00FFFFFF
CeFileGenerationMask=0x000000FF
CeFileSizeMask=0x00FFFF00
CeFileSizeOffset =8
CeFileReservedMask=0x4F000000
Cache1Headsize=16384
Cache1Blocksize=256
Cache2Headsize=4096
Cache2Blocksize=1024
Cache3Headsize=1024
Cache3Blocksize=4096
CacheMHeadersize=276
Recordindexsize=16
bCache=false
bProfile=false
proPath=''
cahPath=''


  ############################################################################
  ############################  Define color  ################################
  ############################################################################
  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def 
    red(text); colorize(text, 31); 
    end
  def 
    green(text); colorize(text, 32);
  end
  
  def 
    yellow(text); colorize(text, 33); 
  end

  def 
    pink(text); colorize(text, 35); 
  end

  ############################################################################
  ############################  check FF bookmark  ###########################
  ############################################################################

  def chkBookmark (fpath)
    #check if  sqlite file exit
    dbfile=fpath+'/places.sqlite'
    if(File.exist?(dbfile))
      #check if file readab
      if(File.readable?(dbfile))     
        db=SQLite3::Database.open dbfile
 
        #query the db 
        rows=db.execute "SELECT moz_bookmarks.id,moz_bookmarks.title,datetime(dateAdded/1000000, 'unixepoch') ,datetime(lastModified/1000000, 'unixepoch'),moz_places.url from moz_bookmarks,moz_places where moz_bookmarks.fk=moz_places.id and moz_places.url not like \'place:%\' and moz_places.url not like \'about:%\'   "
            
        #chk howmany records
        it=rows.count 
        puts green("[OK]  	"+it.to_s+ " bookmark records have been found.")
        
        CSV.open("Bookmark.csv", "w") do |csv|
          csv << ["id","BookMark_title", "DataAdded","Last_Modified","URL"]
  
        # write bookmark record to place.csv file
        rows.each{
          |bookmark|
            csv <<bookmark
          }
        end
      else
          puts red("[Fail]  Places.sqlite file is not readable. Please change the file permission first!")
      end
    else
      puts red("[Fail]  Places.Sqlite file is not exist!!!")
    end
    rescue SQLite3::Exception => e     
      puts red("[Fail]  Exception occurred  when process bookmark : "+e)
    ensure
      db.close if db
  end
  
  
  ############################################################################
  #############################  check for auto-complete  ####################
  ############################################################################
  def autocomplete(fpath)
    #check if file exit
    dbfile=fpath+'/formhistory.sqlite'
    if(File.exist?(dbfile))
      #check if file readable
      if(File.readable?(dbfile))
        #f2=File.open('auto-complete.csv',"w+")
        db=SQLite3::Database.open dbfile
        
        #query the db 
        rows=db.execute "SELECT id,fieldname, value,timesUsed ,datetime(firstUsed/1000000, 'unixepoch'),
        datetime(lastUsed/1000000, 'unixepoch') , guid from moz_formhistory"

        #chk howmany records
        it=rows.count 
        puts green("[OK]  	"+it.to_s+" auto-complete records have been found.")
  
        CSV.open("Autocomplete.csv", "w") do |csv|
          csv << ["id","fieldname", "fieldvalue", "timesused", "1stUsed", "LastUsed", "guid"]
  
        # write auto-complete record to place.csv file
        rows.each{
          |autocom|
      		  csv << autocom
          }
        end
     else
      puts red("[Fail]  Formhistory.sqlite file is not readable. Please change the file permission first!")
     end
    else
    puts red("[Fail]  Formhistory.sqlite file is not exist!!!")
    end
  rescue SQLite3::Exception => e    
      puts red("[Fail]  Exception occurred  when process auto-complete : "+e)  
  ensure
      db.close if db

  end
  
    
  ############################################################################
  #############################  check for Download  #########################
  ############################################################################
  def chkDownload(fpath)
    #check if file exit
    dbfile=fpath+'/downloads.sqlite'
    if(File.exist?(dbfile))
      #check if file readable
      if(File.readable?(dbfile)) 
        db=SQLite3::Database.open dbfile
        
        #query the db 
        rows=db.execute "SELECT id,name,mimetype,source ,datetime(starttime/1000000, 'unixepoch') ,
          datetime(endtime/1000000, 'unixepoch') ,target ,referrer, maxbytes,preferredapplication,state from moz_downloads"
        # for version before  library implementation
        	it=rows.count 
        
        	CSV.open("Download.csv", "w") do |csv|
          	csv << ["id","Name", "FileType", "DownloadSource", "DownloadStart", "DownloadEnd", "FileSaved", "ReferPage", "FileSize", "ApptoOpendownload", "Downloadstate","FirstAttemptStart","LastAttemptStart","LastDownloadstate","LastDownloadEnd"]
  
        	# write download record to download.csv file
        	rows.each{
          		|download|
      			csv << download
          }
        	
  		    it=it.to_i
    		  #check if file exit
    		  dbfile2=fpath+'/places.sqlite'
    		  if(File.exist?(dbfile2))
      			#check if file readable
      			if(File.readable?(dbfile2))
        			db2=SQLite3::Database.open dbfile2
        
        			#query the db  to find download attributes id
		          idstFileURI=db2.execute "SELECT id from moz_anno_attributes where name= 'downloads/destinationFileURI'"
				      idstFileName=db2.execute "SELECT id from moz_anno_attributes where name= 'downloads/destinationFileName'"
				      idstFileMetaData=db2.execute "SELECT id from moz_anno_attributes where name= 'downloads/metaData'"

				      # retrevie downloads placeid
				      iplace_ids=db2.execute "SELECT distinct  moz_annos.place_id  from moz_annos where moz_annos.anno_attribute_id ="+idstFileURI.to_s
			
				      iplace_ids.each{
					     |place_id|
					     filetype=''
					     downloadStart=''
					     downloadEnd=''	
					     referPage=''
					     apptoOpendownload=''
					     downloadstate=''
					     dstFileURI=db2.execute "SELECT content from moz_annos where anno_attribute_id ="+idstFileURI.to_s+" and place_id="+place_id.to_s
					     dstFileName=db2.execute "SELECT content from moz_annos where anno_attribute_id ="+idstFileName.to_s+" and place_id="+place_id.to_s

					
					     url=db2.execute "SELECT url from moz_places where id="+place_id.to_s
					     drow=db2.execute "select datetime( moz_annos.dateAdded/1000000, 'unixepoch'),datetime( moz_annos.lastModified/1000000, 'unixepoch') from moz_annos where place_id="+place_id.to_s

					     firstAttempt=drow[0][0]
					     lastAttempt=drow[0][1]
					
					     if idstFileMetaData[0].nil?
						    # version < 20 and exit
						    db2.close					
						    break;
					     end
					
					     unless idstFileMetaData.to_s.empty?

						    dstFileMetaData=db2.execute "SELECT content from moz_annos where anno_attribute_id ="+idstFileMetaData.to_s+" and place_id="+place_id.to_s
					     end

						  unless dstFileMetaData[0].nil?
							
							 sMetaData=dstFileMetaData[0].to_s
							 state=sMetaData[sMetaData.index(':')+1 , sMetaData.index(',')-sMetaData.index(':')-1]
							
							 if(state=='3')
								  stmp=sMetaData[sMetaData.index(',')+1 , sMetaData.length-sMetaData.index(',')]
  								endtime=stmp[stmp.index(':')+1 , stmp.index('}')-stmp.index(':')-2]
  								endtime=DateTime.strptime(((endtime.to_i/100).to_s),'%s').to_s
  								endtime=endtime.gsub("+00:00", '');
								  filesize=''
  						else
								stmp=sMetaData[sMetaData.index(',')+1 , sMetaData.length-sMetaData.index(',')]
								endtime=stmp[stmp.index(':')+1 , stmp.index(',')-stmp.index(':')-2]
								endtime=DateTime.strptime(((endtime.to_i/100).to_s),'%s').to_s
								endtime=endtime.gsub("+00:00", '');
								stemp=sMetaData.reverse
								filesize= stemp[stemp.index('}')+1, stemp.index(':')-1]
								filesize=filesize.reverse								
							end
							
						end
					csv << [ place_id.to_s,dstFileName, filetype,url,downloadStart,downloadEnd,dstFileURI,referPage,filesize,apptoOpendownload,downloadstate,firstAttempt,lastAttempt, state,endtime]
					it=it+1
				  } 
            puts green("[OK]  	"+it.to_s+ " download records have been found.")
     			else
     			 	puts red("[Fail]  places.sqlite file is not readable. Please change the file permission first!")
     			end 
    		else
    			puts red("[Fail]  places.sqlite file is not exist!!!")
    		end # end if

		  db2.close if db2
		  end # end csv
    else
    		puts red("[Fail]  Downloads.sqlite file is not readable. Please change the file permission first!")
    end
    else
    	puts red("[Fail]  Download.sqlite file is not exist!!!")
    end
    rescue SQLite3::Exception => e   
      puts red("[Fail]  Exception occurred  when process download : "+e)
    ensure
      db.close if db
      #db2.close if db2
  end
  
  
  ############################################################################
  #############################  check for Cookie  #########################
  ############################################################################
  def chkCookies(fpath)
    dbfile=fpath+'/cookies.sqlite'
    #check if file exit
    if(File.exist?(dbfile))
      #check if file readable
      if(File.readable?(dbfile))
        db=SQLite3::Database.open dbfile
        #query the db ,localtime
        rows=db.execute "SELECT moz_cookies.id,moz_cookies.host,moz_cookies.path,moz_cookies.name,moz_cookies.value,moz_cookies.isSecure,datetime(moz_cookies.creationTime/1000000, 'unixepoch'),datetime(moz_cookies.lastAccessed/1000000, 'unixepoch'),datetime( moz_cookies.expiry, 'unixepoch') from moz_cookies order by moz_cookies.id"
  
        #chk howmany records
        it=rows.count 
        puts green("[OK]  	"+it.to_s+ " cookie records have been found.")

        CSV.open("Cookies.csv", "w") do |csv|
        csv << ["id","Host", "Path","Name","Value","IsSecure","CreationTime","LastAccessed","Expiry"]
        rows.each{
          |cookies|
            csv << cookies
           }
        end
      else
        puts red("[Fail]  Cookies.sqlite file is not readable. Please change the file permission first!")
      end
    else
      puts red("[Fail]  Cookies.Sqlite file is not exist!!!")
    end
    rescue SQLite3::Exception => e 
      puts red("[Fail]  Exception occurred  when process cookie : "+e)
    ensure
      db.close if db
  end
  
  
  ############################################################################
  #############################  check for DomStorage  #######################
  ############################################################################
  def chkDomStorage(fpath)
      #check if file exit
      dbfile=fpath+'/webappsstore.sqlite'
      if(File.exist?(dbfile))
        #check if file readable
        if(File.readable?(dbfile))
          db=SQLite3::Database.open dbfile
          #query the db
          rows=db.execute "SELECT webappsstore2.rowid,webappsstore2.scope,webappsstore2.key,webappsstore2.value,webappsstore2.secure from webappsstore2 order by webappsstore2.rowid"
  
          #chk howmany records
          it=rows.count 
          puts green("[OK]  	"+it.to_s+ " DOM storage records have been found.")

          CSV.open("Domstorage.csv", "w") do |csv|
          csv << ["id","Scope", "key","value","Secure"]
            rows.each{
              |dom|  
            		#remove new line, tab
            		dom[3]=dom[3].gsub("\n",'')
            		dom[3]=dom[3].gsub("\t",'')
            		# CSV limitation , max size is 32761
            		if dom[3].length>32761
            			exfile=File.new((dom[0]+"-value.txt"), "w+")
            			exfile.puts(dom[3])
            			exfile.close
            			dom[3]="Data is too big. For more information, please check the external file"+dom[0]+"-value.txt"
            		end
		
                csv << dom
             }
            end
        else
          puts red("[Fail]  Webappsstore.sqlite file is not readable. Please change the file permission first!")
        end
      else
        puts red("[Fail]  Webappsstore.sqlite file is not exist!!!")
      end
  rescue SQLite3::Exception => e 
    puts red("[Fail]  Exception occurred  when process Dom storage : "+e ) 
  ensure
    db.close if db
  end
  
  
  ############################################################################
  ######################  check for web browsing history  ####################
  ############################################################################
  def chkHistory(fpath)
    #check if file exit
    dbfile=fpath+'/places.sqlite'
    if(File.exist?(dbfile))
      #check if file readable
      if(File.readable?(dbfile))
        db=SQLite3::Database.open dbfile
        puts green("[Info]	Extracting web history could take a few mins.......")
        #query the db 
        rows=db.execute "SELECT moz_historyvisits.id,moz_places.url,moz_places.title,datetime( moz_historyvisits.visit_date/1000000, 'unixepoch') ,datetime(moz_places.last_visit_date/1000000, 'unixepoch') ,moz_places.visit_count,moz_places.typed,moz_places.hidden,moz_historyvisits.from_visit,moz_historyvisits.visit_type from moz_historyvisits,moz_places where moz_historyvisits.place_id= moz_places.id order by moz_historyvisits.id"
 
        #chk howmany records
        it=rows.count 
        puts green("[OK]  	"+it.to_s+ " web browsing history records have been identified.")
        puts green("[Info]	Writing web history records to CSV file.......")
        CSV.open("webhistory.csv", "w") do |csv|
          csv << ["id","URL", "Title","FirstVisitDate","LastVisitDate","VisitCount","TypedURL","Hidden","FromVisit","VisitType"]
          rows.each{
            |history| 
            csv << history
          }
      end
      else
        puts red("[Fail]  places.sqlite file is not readable. Please change the file permission first!")
      end
    else
      puts red("[Fail]  Places.Sqlite file is not exist!!!")
    end
  rescue SQLite3::Exception => e 
    puts red("[Fail]  Exception occurred  when process history : "+e)
  ensure
    db.close if db
  end


  ############################################################################
  ############################  check FF Extensions  ###########################
  ############################################################################

  def chkExtensions (fpath)
    #check if file exit
    dbfile=fpath+'/extensions.sqlite'
    if(File.exist?(dbfile))
      #check if file readable
      if(File.readable?(dbfile))
        db=SQLite3::Database.open dbfile
        #query the db 
        rows=db.execute "SELECT locale.name, addon.version,datetime(installDate/1000, 'unixepoch') ,datetime(updateDate/1000, 'unixepoch'),addon.sourceURI, active from addon,locale where addon.defaultLocale=locale.id order by active "
 
        #chk howmany records
        it=rows.count 
        puts green("[OK]  	"+it.to_s+ " extension records have been found.")
        CSV.open("Extension.csv", "w") do |csv|
          csv << ["name","version", "installDate","updateDate","SourceURL","active"]
          rows.each{
            |extension| 
            csv << extension
          }
      end
      else
        puts red("[Fail]  extension.sqlite file is not readable. Please change the file permission first!")
      end
    else
      puts red("[Fail]  extension.Sqlite file is not exist!!!")
    end
  rescue SQLite3::Exception => e 
    puts red("[Fail]  Exception occurred  when process extension : "+e)
  ensure
    db.close if db 
  end

 

  ##################################################################
  ######################  check for Cache file  ####################
  ##################################################################
  def chkCache(fpath)
    puts green("[Info]  F0xChas3r is chasing the Firefox cache records for you now.")
    puts green("[Info]  Extracting cache records could take a few mins.......")
    fileCacheMap =fpath+"/_CACHE_MAP_"
  
    if(File.exist?(fileCacheMap))
      #check if file readable
      if(File.readable?(fileCacheMap))
        CSV.open("Cache.csv", "w")  do |csv|
          csv << ["FileName","ContentType", "URL","FetchCount","LastModified","LastFetch","ExpirationTime","ServerResponseCode","ExternalCachefile"]
      
          #check cache_map file size
          size=File.size(fileCacheMap)
          # find the total records number
          iNo=(size-CacheMHeadersize)/Recordindexsize
      
          iRcord=0
          for i in 0..(iNo-1)            
            filename=""
            contype=""
            srequest=""
            fetchcount=""
            lastmodified=""
            lastfetch=""
            expiretime=""
            srescode="" 
            exfilename="No"
            
            startpoint=CacheMHeadersize+i*Recordindexsize
            fstRecord=IO.read(fileCacheMap,Recordindexsize,startpoint)

            #find metadata location
            lmetalocaltion=fstRecord.unpack('N*')[3]
            
            #for data external file
            ldatalocaltion=fstRecord.unpack('N*')[2]
            
            filepath=fstRecord.unpack('N*')[0]
          
            #Find Cache file that store metadata _data ?
            iCachemfileNo=(lmetalocaltion&CeLocationSelectorMask)>>CeLocationSelectorOffset
            iCachedfileNo=(ldatalocaltion&CeLocationSelectorMask)>>CeLocationSelectorOffset        
            
            
            if (lmetalocaltion!=0&&iCachemfileNo!=0)   
              
              if iCachedfileNo.eql?(0)
                # find data/metadata file location
                filepath=fstRecord.unpack('N*')[0].to_s 16
             
                if  (filepath.length<8 &&filepath.length>5)
                  ipadNo=8-filepath.length
                #  puts "filepath orig  "+filepath
                  filepath="0"*ipadNo+filepath
                #  puts "filepath aft pad is "+filepath
                end                 
                  
                #generation number
                datalocation=fstRecord.unpack('N*')[2]
                genno=datalocation & CeFileGenerationMask
                if (genno.eql?(0)||filepath=="0")
                else
            
                exfilename="\\"+filepath[0,1]+"\\"+filepath[1,2]+"\\"+filepath[3,5]+"d0"+genno.to_s
                end
               
              end    
    
              #---------------------find record entry-----------------           
              sCacheName="_CACHE_00"+iCachemfileNo.to_s+"_"
              #find startblock and blockcount 
              startblock=lmetalocaltion & CeBlockNumberMask
              blockcount=((lmetalocaltion&CeExtraBlocksMask)>>CeExtraBlocksOffset)+1

              #retrevie metadata startblock and size
              if sCacheName.eql?("_CACHE_001_")
                mdstart=Cache1Headsize+Cache1Blocksize*startblock
                mdsize=Cache1Blocksize*blockcount
              elsif sCacheName.eql?("_CACHE_002_")
                mdstart=Cache2Headsize+Cache2Blocksize*startblock
                mdsize=Cache2Blocksize*blockcount
              elsif sCacheName.eql?("_CACHE_003_")
                mdstart=Cache3Headsize+Cache3Blocksize*startblock
                mdsize=Cache3Blocksize*blockcount
              end              
                
              sCacheName=fpath+'/'+sCacheName
                
              #retrive whole record 
              mdrecord=IO.read(sCacheName,mdsize,mdstart)
              unless mdrecord.nil?  
                mdlength=mdrecord.unpack('N*').length
                fetchcount=mdrecord.unpack('N*')[2]

                #last fectch 12-15
                lastfetch=mdrecord.unpack('N*')[3].to_s                   
                lastfetch=DateTime.strptime(lastfetch,'%s')
              
                #last modified
                lastmodified=mdrecord.unpack('N*')[4].to_s
                lastmodified=DateTime.strptime(lastmodified,'%s')
              
                #expiretme
                expire=mdrecord.unpack('N*')[5].to_s
                expiretime=DateTime.strptime(expire,'%s').to_s
              
                #data size
                datasize=mdrecord.unpack('N*')[6]
              
                #request size
                requestsize=mdrecord.unpack('N*')[7]
                requestsize=requestsize.to_i
             
                #sever response size
                ssize=mdrecord.unpack('N*')[8]
                
                # if its string io can read and display as string
                #only retrieve 30bit to check if HTTP insise
                #srequest=mdrecord[36,requestsize]
                srequest=mdrecord[36,30]

                #add 20130331 chk if HTTP in the srequest in case the legitmate bolck doesnt have read http artificart
                icheckHTTP=srequest.index('HTTP:')
                unless icheckHTTP.nil?
                  srequest=mdrecord[36,requestsize]
                  srequest=srequest.gsub('HTTP:', '')
                  filename=srequest.reverse
          
                  ifindex=filename.index('/')
                  filename=filename[0,ifindex]
                  filename=filename.reverse
      	          ifindex=filename.index('?')
      	          unless ifindex.nil?
                    #filename=filename[(ifindex+1),(filename.length-ifindex)]
                  	filename=filename[0,ifindex]   
                  end             
                  # server response
                  sresponse=mdrecord[(36+requestsize),2180]
                  unless sresponse.nil?
                    #remove null bytes
                    sresponse=sresponse.gsub("\000", '');
                    sresponse=sresponse.strip
              
                    # get server respond code
                    srescode=sresponse.lines.drop(0).take(1)
                    srescode=(srescode.to_s).gsub('\r', '')
                    srescode=(srescode.to_s).gsub('\n', '')
                    srescode=(srescode.to_s).gsub('"', '')
                    srescode=(srescode.to_s).gsub(']', '')
              
                    i=srescode.index('HTTP/')
                    unless i.nil?
                      srescode=srescode[i,srescode.length]
                      srescode= srescode.strip
                      # get content type
                      contype=sresponse.lines.drop(1).take(1)
             
                      if contype.to_s.index('Content-Type').nil?
                        for ictyp in 2..(sresponse.lines.count)
                          contype=sresponse.lines.drop(ictyp).take(1)
                          #puts contype.to_s.index('Content-Type:')
                          unless contype.to_s.index('Content-Type').nil?
                            break
                          end
                        end
                      end
              
                    contype=(contype.to_s).gsub('\r', '')
                    contype=(contype.to_s).gsub('\n', '')
                    contype=(contype.to_s).gsub('"', '')
                    contype=(contype.to_s).gsub(']', '')
                    contype=(contype.to_s).gsub('[', '')
                    contype=(contype.to_s).gsub('Content-Type: ', '')
                    contype=contype.strip
                    end

                    csv <<[ filename, contype,srequest,fetchcount,lastmodified,lastfetch,expiretime,srescode,exfilename]
                    iRcord=iRcord + 1
                  end
                end
              end
            end
          end
           puts green("[OK]  	"+iRcord.to_s+ " cache records are identified.")
      end
    else
      puts red("[Fail]  _CACHE_MAP_ file is not readable. Please change the file permission first!")
    end
    else
      puts red("[Fail]  _CACHE_MAP_ file is not exist!!!")
    end
  end


   options = {}
   optparse = OptionParser.new do|opts|
   opts.banner =yellow("
  ✄╭━━━┳━━━╮╱╱╭━━━┳╮╱╱╱╱╱╱╱╭━━━╮
  ✄┃╭━━┫╭━╮┃╱╱┃╭━╮┃┃╱╱╱╱╱╱╱┃╭━╮┃
  ✄┃╰━━┫┃┃┃┣╮╭┫┃╱╰┫╰━┳━━┳━━╋╯╭╯┣━╮
  ✄┃╭━━┫┃┃┃┣╋╋┫┃╱╭┫╭╮┃╭╮┃━━╋╮╰╮┃╭╯
  ✄┃┃╱╱┃╰━╯┣╋╋┫╰━╯┃┃┃┃╭╮┣━━┃╰━╯┃┃  version 0.2.0
  ")
    opts.separator  "F0xChas3r - Firefox forensic tool by Andy Yang[contactayangATgmailDOTcom]; "
    opts.separator ""
    opts.separator  "EXAMPLE USAGE:"
    opts.separator  "     ./F0xChas3r.rb  -p \'/Mozilla/Firefox/Profiles/<random text>.default\' -c \'/Mozilla/Firefox/profiles/<random text>.default/Cache\'
  "
   
    # Define the options
    options[:cache] = nil
    opts.on( '-c', '--cache path', 'specify user cache location.') do|filepath|
      options[:cache] = filepath  
      if  File.directory?(options[:cache])
        bCache=true
        cahPath= filepath
      else
        puts red("[Fail]  Firefox cache folder is not exist, please check it again!")
      end  
    end
     
    options[:profile] = nil
    opts.on( '-p', '--profile path', 'specify user profile location.' ) do |filepath|
       options[:profile] = filepath
       if  File.directory?(options[:profile])
          bProfile=true
          proPath=filepath
       else
          puts red("[Fail]  Firefox profile folder is not exist, please check it again!")
       end 
     end
       
    opts.on( '-h', '--help', 'Display help' ) do
    puts opts
    exit
    end
   end
   
   begin optparse.parse! ARGV  
   rescue OptionParser::InvalidOption => e
    puts e
    puts optparse
    exit 1
  end 
 
    if(bProfile==true||bCache==true)
      puts green("[Info]  F0xChas3r is chasing the Firefox for you now.")
      if(options[:profile]&& bProfile=l=true)
        autocomplete(proPath)
        chkBookmark(proPath)
        chkDownload(proPath)
        chkCookies(proPath)
        chkDomStorage(proPath)
        chkHistory(proPath)
        chkExtensions(proPath)
      end
      if(options[:cache]&&bCache==true)
        chkCache(cahPath)
      end  
      puts pink("\e[1m[DONE]  Please check the output CSV files for details.\e[0m")
    else
        puts optparse
    end      







