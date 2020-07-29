# encoding: utf-8
# Menu Title: Smoke Test
# Needs Case: true
# Needs Selected Items: false
# Author: Cameron Stiller
# Version: 1.4
# Comment: Please note this has been provided as a guide only and should be thoroughly tested before entering production use.

if($current_case.nil?)
	if(	ENV_JAVA.has_key? "case" )
		$case_dir=ENV_JAVA["case"]
	else
		puts "ERROR!! No case specified"
		exit
	end
	if(	ENV_JAVA.has_key? "migrate" )
		$migrate=(ENV_JAVA["migrate"].downcase()==true.to_s.downcase)
	else
		puts "ERROR!! Migrate flag not specified..."
		exit
	end

	begin
		caseutility=$utilities.getCaseFactory()
		$current_case = caseutility.open($case_dir,{"migrate"=>$migrate})
	rescue Exception=> migrate_error
		puts migrate_error.message
	end
else
	$UI=true
end

def escapeQuotations(theString)
	#escape all the quotations that can mess with searching/counts
	temp=theString.encode('utf-8').gsub("\"","\\\"")
	temp=temp.gsub("\u201C","\\\u201C") # these are the unicode double quote equivelant
	temp=temp.gsub("\u201D","\\\u201D") # these are the unicode double quote equivelant
	return temp
end


begin
	#older nuix's don't have json... so instead using pp
	#require 'json'
	require 'pp'
	require 'fileutils'
	verbose=true

	def java_to_ruby(obj,debug=false)
		puts "DEBUG" if debug
		puts obj if debug
		case
		when obj.class==String
			if(obj.to_s.start_with? "{\"")
				begin
					return eval(obj.to_s)
				rescue Exception > ex
					puts obj.to_s
					puts ex.message if debug
					exit
				end
			else
				return obj.to_s
			end
		when obj.class==FalseClass
			return false
		when obj.class==TrueClass
			return true
		when obj.class==Fixnum
			return obj.to_i
		when obj.class==Java::OrgJodaTime::DateTime
			return obj.toString()
		else
			puts "Unknown Class... defaulting to proximation:#{obj.class}" if debug
		end
		begin
			val=obj.to_h
			new_hash=Hash.new()
			val.keys.sort().each do |k|
				puts k if debug
				new_hash[k]=java_to_ruby(val[k],debug)
			end
			puts "0 - #{new_hash}" if debug
			return new_hash.sort_by{|k,v|k}
		rescue Exception => ex
			puts ex.message if debug
		end
		begin
			val=obj.to_a
			if(val.all? {|entry|entry.length ==2})
				new_hash=Hash.new()
				val.each do | key,value|
					new_hash[key]=java_to_ruby(value,debug)
				end
				puts "1 - #{new_hash}" if debug
				return new_hash.sort_by{|k,v|k}
			else
				val=val.map{|v|java_to_ruby(v,debug)}
				puts "2 - #{val}" if debug
				return val.sort()
			end
		rescue
		end
		begin
			new_hash=Hash.new()
			obj.each do |k,v|
				if(! (v.nil?))
					new_hash[k]=java_to_ruby(v,debug)
				end
			end
			if(new_hash.keys.length > 0)
				puts "3 - #{new_hash}" if debug
				return new_hash.sort_by{|k,v|k}
			end
		rescue
		end
		begin
			new_array=Array.new()
			obj.each do |v|
				new_array.push java_to_ruby(v,debug)
			end
			puts "4 - #{new_array}" if debug
			return new_array.sort()
		rescue
		end
		puts "5 - defaulting... #{obj.toString()}" if debug
		return obj.toString()
	end



	smoke_test=Hash.new()
	smoke_test["Digests"]=Array.new()



	puts "summary" if verbose
	smoke_test["Summary"]={
		"Name"=>$current_case.respond_to?(:getName) ? $current_case.getName() : "???",
		"Description"=>$current_case.respond_to?(:getDescription) ? $current_case.getDescription() : "???",
		"GUID"=>$current_case.respond_to?(:getGuid) ? $current_case.getGuid().to_s : "???",
		"Count"=>$current_case.respond_to?(:count) ? $current_case.count("").to_s : "???",
		"Comments"=>$current_case.respond_to?(:count) ? (begin $current_case.count("comment:*").to_s 
		rescue Exception=>ex
		{"ERROR"=>ex.message,"Backtrace"=>ex.backtrace} 
		end) : "???",
		"Custodians"=>$current_case.respond_to?(:getAllCustodians) ? $current_case.getAllCustodians().sort().length.to_s : "???",
		"Entities"=>$current_case.respond_to?(:getAllEntityTypes) ? $current_case.getAllEntityTypes().sort().length.to_s : "???",
		"Exclusions"=>$current_case.respond_to?(:getAllExclusions) ? $current_case.getAllExclusions().sort().length.to_s : "???",
		"ItemSets"=>$current_case.respond_to?(:getAllItemSets) ? $current_case.getAllItemSets().length.to_s : "???",
		"OriginalExtensions"=>$current_case.respond_to?(:getAllOriginalExtensions) ? $current_case.getAllOriginalExtensions().length.to_s : "???",
		"Tags"=>$current_case.respond_to?(:getAllTags) ? $current_case.getAllTags().length.to_s : "???",
		"Users"=>$current_case.respond_to?(:getAllUsers) ? $current_case.getAllUsers().length.to_s : "???",
		"BatchLoads"=>$current_case.respond_to?(:getBatchLoads) ? $current_case.getBatchLoads().length.to_s : "???",
		"ClusterRuns"=>$current_case.respond_to?(:getClusterRuns) ? $current_case.getClusterRuns().length.to_s : "???",
		"Case CustomMetadata"=>$current_case.respond_to?(:getCustomMetadata) ? $current_case.getCustomMetadata().keys.length.to_s : "???",
		"CustomMetadataFields"=>$current_case.respond_to?(:getCustomMetadataFields) ? $current_case.getCustomMetadataFields().length.to_s : "???",
		"MetadataItems"=>$current_case.respond_to?(:getMetadataItems) ? $current_case.getMetadataItems().select{|meta|meta.getType() != "SPECIAL"}.length.to_s : "???",
		"InvestigationTimeZone"=>$current_case.respond_to?(:getInvestigationTimeZone) ? $current_case.getInvestigationTimeZone().to_s : "???",
		"Investigator"=>$current_case.respond_to?(:getInvestigator) ? $current_case.getInvestigator().to_s : "???",
		"Location"=>$current_case.respond_to?(:getLocation) ? $current_case.getLocation().to_s : "???",
		"Languages"=>$current_case.respond_to?(:getLanguages) ? $current_case.getLanguages().length.to_s : "???",
		"MarkupSets"=>$current_case.respond_to?(:getMarkupSets) ? $current_case.getMarkupSets().length.to_s : "???",
		"ProductionSets"=>$current_case.respond_to?(:getProductionSets) ? $current_case.getProductionSets().length.to_s : "???",
		"ReviewJobs"=>$current_case.respond_to?(:getReviewJobs) ? $current_case.getReviewJobs().length.to_s : "???",
		"RootItems"=>$current_case.respond_to?(:getRootItems) ? $current_case.getRootItems().length.to_s : "???",
		"isCompound"=>$current_case.respond_to?(:isCompound) ? $current_case.isCompound().to_s : "???",
		"NUIX_VERSION"=>NUIX_VERSION.nil? ? "???" : NUIX_VERSION.to_s,
	}
	puts "statistics" if verbose

	smoke_test["Statistics"]=Hash.new{}

	puts "users" if verbose
	smoke_test["Statistics"]["Users"]=$current_case.respond_to?(:getAllUsers) ? $current_case.getAllUsers().sort_by{|user|user.getLongName()}.map { | user|
		{
			"LongName"=>java_to_ruby(user.getLongName()),
			"ShortName"=>java_to_ruby(user.getShortName())
		}
	} : "???"

	puts "custodians" if verbose
	smoke_test["Statistics"]["Custodians"]=$current_case.respond_to?(:getAllCustodians) ? $current_case.getAllCustodians().sort().map { | custodian|
		{
			"Name"=>java_to_ruby(custodian),
			"Count"=>$current_case.count("custodian:\"#{escapeQuotations(custodian)}\"")
		}
	} : "???"

	puts "Entities" if verbose
	smoke_test["Statistics"]["Entities"]=$current_case.respond_to?(:getAllEntityTypes) ? $current_case.getAllEntityTypes().sort().map { | entity|
		{
			"Name"=>java_to_ruby(entity),
			"Count"=>$current_case.count("named-entities:#{escapeQuotations(entity)};*")
		}
	}: "???"
	
	smoke_test["Statistics"]["Exclusions"]=$current_case.respond_to?(:getAllExclusions) ? $current_case.getAllExclusions().sort().map { | exclusion|
		{
			"Name"=>java_to_ruby(exclusion),
			"Count"=>$current_case.count("exclusion:\"#{escapeQuotations(exclusion)}\"")
		}
	} : "???"
		

	smoke_test["Statistics"]["Item Sets"]=Hash.new()
	puts "Item Sets" if verbose
	smoke_test["Statistics"]["Item Sets"]=$current_case.respond_to?(:getAllItemSets) ? $current_case.getAllItemSets().sort_by{|itemset|itemset.getName()}.map { | itemset|
		{
			"Name"=>itemset.getName(),
			"Description"=>itemset.getDescription(),
			"Settings"=>itemset.respond_to?(:getSettings) ? java_to_ruby(itemset.getSettings()) : "???",
			"Originals"=>itemset.respond_to?(:getBatches) ? itemset.getBatches().sort_by{|batch|batch.getName()}.map{| batch|
				name=batch.getName().to_s
				originals=itemset.getOriginals(name)
				{
					"Name"=>name,
					"Created"=>java_to_ruby(batch.getCreated()),
					"Count"=>originals.length(),
					"Items"=>originals.map(&:getGuid).sort(),
					
				}
			} : itemset.getOriginals("").map(&:getGuid).sort(),
			"Duplicates"=>itemset.respond_to?(:getBatches) ? itemset.getBatches().sort_by{|batch|batch.getName()}.map{| batch|
				name=batch.getName().to_s
				duplicates=itemset.getDuplicates(name)
				{
					"Name"=>name,
					"Created"=>java_to_ruby(batch.getCreated()),
					"Count"=>duplicates.length(),
					"Items"=>duplicates.map(&:getGuid).sort(),
					
				}
			} : itemset.getOriginals("").map(&:getGuid).sort(),
		}
	} : "???"
	
	

	puts "Tags" if verbose
	smoke_test["Statistics"]["Tags"]=$current_case.respond_to?(:getAllTags) ? $current_case.getAllTags().sort().map{ | tag|
		{
			"Name"=>tag,
			"Count"=>$current_case.count("tag:\"#{escapeQuotations(tag)}\"")
		}
	} : "???"

	puts "BatchLoads" if verbose
	smoke_test["Statistics"]["BatchLoads"]=$current_case.respond_to?(:getBatchLoads) ? $current_case.getBatchLoads().sort_by{|batchload|batchload.getBatchId()}.map{ | batchload|
		{
			"BatchId"=>batchload.getBatchId(),
			"AdditionalSettings"=>java_to_ruby(batchload.getAdditionalSettings()),
			"CaseEvidenceSettings"=>java_to_ruby(batchload.getCaseEvidenceSettings()),
			#This fails because in each version of Nuix we add settings.... 
			"DataProcessingSettings"=>java_to_ruby(batchload.getDataProcessingSettings()),
			#This fails because in each version of Nuix we add settings.... 
			"DataSettings"=>java_to_ruby(batchload.getDataSettings()),
			"Items"=>batchload.getItems().map(&:getGuid).sort(),
			"Loaded"=>batchload.getLoaded().to_s,
			"OperatingSystem"=>batchload.getOperatingSystem().to_s,
			"OperatingSystemArchitecture"=>batchload.getOperatingSystemArchitecture().to_s,
			"ParallelProcessingSettings"=>java_to_ruby(batchload.getParallelProcessingSettings()),
			"ProcessArchitecture"=>batchload.getProcessArchitecture().to_s
		}
	} : "???"

	puts "Cluster Runs" if verbose
	smoke_test["Statistics"]["Cluster Runs"]=$current_case.respond_to?(:getClusterRuns) ? $current_case.getClusterRuns().sort_by{|clusterrun|clusterrun.getName()}.map { | clusterrun|
		{
			"Name"=>clusterrun.getName(),
			"ResemblanceThreshold"=>clusterrun.respond_to?(:getResemblanceThreshold) ? clusterrun.getResemblanceThreshold().to_s : "???",
			"UseChainedNearDuplicates"=>clusterrun.respond_to?(:getUseChainedNearDuplicates) ? clusterrun.getUseChainedNearDuplicates().to_s : "???",
			"UseEmailThreads"=>clusterrun.respond_to?(:getUseEmailThreads) ? clusterrun.getUseEmailThreads().to_s : "???",
			"Clusters"=>clusterrun.getClusters().sort_by{|cluster|cluster.getId()}.map{|cluster|
				{
					"ID"=>cluster.getId(),
					"Items"=>cluster.getItems().map{ |item|
						{
							"GUID"=>item.getItem().getGuid(),
							"PivotResemblance"=>item.getPivotResemblance(),
							"isPivot"=>item.isPivot(),
						}
					}.sort_by{|item|item["GUID"]}
				}
			}
		}
	} : "???"

	puts "Custom Metadata" if verbose
	smoke_test["Statistics"]["Custom Metadata"]=$current_case.respond_to?(:getCustomMetadata) ? java_to_ruby($current_case.getCustomMetadata()) : ""

	puts "CustomMetadataFields" if verbose
	smoke_test["Statistics"]["CustomMetadataFields"]=$current_case.respond_to?(:getCustomMetadataFields) ? java_to_ruby($current_case.getCustomMetadataFields()) : ""


	smoke_test["Statistics"]["Item Types"]=$current_case.respond_to?(:getCustomMetadata) ? $current_case.getItemTypes().sort_by{|itemtype|itemtype.getName}.map { |itemtype|
		{
			"Name"=>itemtype.getName,
			"Kind"=>java_to_ruby(itemtype.getKind()),
			"LocalisedName"=>itemtype.getLocalisedName(),
			"PreferredExtension"=>itemtype.getPreferredExtension()
		}
	} : "???"
	
	smoke_test["Statistics"]["Metadata Types"]=$current_case.respond_to?(:getMetadataItems) ? $current_case.getMetadataItems().select{|meta|meta.getType() != "SPECIAL"}.sort_by{|metatype|"#{metatype.getType()}#{metatype.getName}"}.map { |metatype|
		{
			"Name"=>metatype.getName,
			"Type"=>metatype.getType(),
			"LocalisedName"=>metatype.getLocalisedName()
		}
	} : "???"




	puts "Markup Sets" if verbose
	smoke_test["Statistics"]["Markup Sets"]=$current_case.respond_to?(:getMarkupSets) ? $current_case.getMarkupSets().sort_by{|markupset|markupset.getName()}.map{|markupset|
		{
			"getDescription"=>markupset.getDescription(),
			"Name"=>markupset.getName(),
			"RedactionReason"=>markupset.getRedactionReason(),
		}
	} : "???"

	puts "Production Sets" if verbose
	smoke_test["Statistics"]["Production Sets"]=$current_case.respond_to?(:getProductionSets) ? $current_case.getProductionSets().sort_by{|productionset|productionset.getName()}.map{|productionset|
		{
			"Description"=>productionset.respond_to?(:getDescription) ? productionset.getDescription().to_s : "???",
			#fails on early 7.3 beta's due to nuix code bug
			"FirstDocumentNumber"=>begin
									productionset.respond_to?(:getFirstDocumentNumber) ? productionset.getFirstDocumentNumber().to_s : "???"
								rescue Exception=>ex
									{"ERROR"=>ex.message,
									"Backtrace"=>ex.backtrace} 
								end,
			"Guid"=>productionset.respond_to?(:getGuid) ? productionset.getGuid().to_s : "???",
			"ImagingSettings"=>productionset.respond_to?(:getImagingSettings) ? java_to_ruby(productionset.getImagingSettings()) : "???",
			"Name"=>productionset.respond_to?(:getName) ? productionset.getName().to_s : "???",
			#fails on early 7.3 beta's due to nuix code bug
			"NextDocumentNumber"=>begin 
									productionset.respond_to?(:getNextDocumentNumber) ? productionset.getNextDocumentNumber().to_s : "???" 
								rescue Exception=>ex
									{"ERROR"=>ex.message,
									"Backtrace"=>ex.backtrace}
								end,
			"isAutoGeneratePrintPreviews"=>productionset.respond_to?(:isAutoGeneratePrintPreviews) ? productionset.isAutoGeneratePrintPreviews().to_s : "???",
			"MarkupSets"=>productionset.respond_to?(:getMarkupSets) ? productionset.getMarkupSets().map(&:getName).to_s : "???",
			"NumberingOptions"=>productionset.respond_to?(:getNumberingOptions) ? productionset.getNumberingOptions().map{|key,value|java_to_ruby(value)} : "???",
			"StampingOptions"=>productionset.respond_to?(:getStampingOptions) ? java_to_ruby(productionset.getStampingOptions()) : "???",
			"ParallelProcessingSettings"=>productionset.respond_to?(:getParallelProcessingSettings) ? java_to_ruby(productionset.getParallelProcessingSettings()) : "???",
			"ImagingOptions"=>productionset.respond_to?(:getImagingOptions) ? java_to_ruby(productionset.getImagingOptions()) : "???",
			"ProductionSettingsSource"=>productionset.respond_to?(:getProductionSettingsSource) ? productionset.getProductionSettingsSource().to_s : "",
			#fails on early 7.3 beta's due to nuix code bug
			"Numbering hash"=>begin
								productionset.respond_to?(:getProductionSetItems) ? productionset.getProductionSetItems().sort_by(&:getDocumentNumber).map{|prod_item|
									{
										"DocumentID"=>prod_item.getDocumentNumber().to_s,
										"ItemGUID"=>prod_item.getItem().getGuid().to_s
									}
								} : "???"
							rescue Exception=>ex
									{"ERROR"=>ex.message,
									"Backtrace"=>ex.backtrace}
							end,
		}
	} : "???"

	puts "Review Jobs" if verbose
	smoke_test["Statistics"]["Review Jobs"]=$current_case.respond_to?(:getReviewJobs) ? $current_case.getReviewJobs().sort_by{|reviewjob|reviewjob.getName()}.map{|reviewjob|
		{
			"Guid"=>reviewjob.respond_to?(:getGuid) ? reviewjob.getGuid().to_s : "",
			"Name"=>reviewjob.respond_to?(:getName) ? reviewjob.getName().to_s : "",
			"ActiveReviewers"=>reviewjob.respond_to?(:getActiveReviewers) ? reviewjob.getActiveReviewers().to_a.map{|reviewer|
				begin
					{
						"Reviewer"=>reviewer.to_s,
						"Assigned Items"=>reviewjob.getItems({"user"=>reviewer}).map(&:getItem).map(&:getGuid), # this bugs out on 4.0 with t.a.b class conversion... bad nuix code.
						"Tags"=>java_to_ruby(reviewjob.getTagCounts(reviewer))
					}
				rescue Exception=>ex
					{
						"Reviewer"=>reviewer.to_s,
						"Assigned Items"=> {"ERROR"=>ex.message,"Backtrace"=>ex.backtrace},
						"Tags"=>java_to_ruby(reviewjob.getTagCounts(reviewer))
					}
				end
				
			} : ""
		}
	} : "???"

	puts "Root Items" if verbose
	smoke_test["Statistics"]["Root Items"]=$current_case.respond_to?(:getRootItems) ? $current_case.getRootItems().sort_by{|rootitem|rootitem.getName()}.map{|rootitem|
		{
			"Name"=>rootitem.respond_to?(:getName) ? rootitem.getName() : "???",
			"Children"=>rootitem.respond_to?(:getChildren) ? rootitem.getChildren().map(&:getGuid) : "???",
			"uri"=>rootitem.respond_to?(:getUri) ? rootitem.getUri() : "???",
		}
	} : "???"

	
	#older nuix's don't have json... so instead using pp
	#puts "...converting to json..." if verbose
	#smoke_test=JSON.pretty_generate(smoke_test)
	#smoke_test=smoke_test.to_json
	puts "...converting to pp..." if verbose
	smoke_test=smoke_test.pretty_inspect
	output="#{$current_case.getLocation()}/smoke"
	FileUtils::mkdir_p output
	File.open("#{output}/#{NUIX_VERSION}.smoke", 'w') {|f| f.write(smoke_test) }
	puts "SUCCESS:#{NUIX_VERSION}"
rescue Exception => ex
	puts "Error generating stats #{ex.message}"
	puts ex.backtrace
ensure
	if($UI.nil?)
		$current_case.close()
	end
end