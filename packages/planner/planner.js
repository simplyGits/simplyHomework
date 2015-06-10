var assert=require("assert");

function HomeworkDescription(){
	if(!(this instanceof HomeworkDescription))return new HomeworkDescription;

	//A unique identifier for a subject. Can be pretty much anything, lest it's a primitive type
	// and unique and fixed, i.e. there is only one identifier per subject and only one subject per identifier.
	this.subject=null;

	//Items in `location` can be multiple things, e.g.
	//- [chapter,paragraph,exercise]
	//- [bookid,page,exercise]
	//- [chapter,exercise]
	//- [bookid,page]
	//In general, anything that can be expressed in a sequence of integers that specifies the location.
	//The `location` property contains an array of those, because homework can be multiple exercises, for example.
	//Please make the array contiguous, though; don't mix indexing conventions! (!) (!!)
	this.location=[];
}

function Planner(){
	if(!(this instanceof Planner))return new Planner;

	var subjects={}; //The Cache

	//`timetaken` in any unit you find convenient; but please be consistent. Suggestion: seconds.
	this.learn=function(hwdesc,timetaken){
		var i,j,idx,subj,loc;
		assert(hwdesc instanceof HomeworkDescription);
		subj=hwdesc.subject;
		loc=hwdesc.location;
		assert(loc.length!=0);
		if(!subjects[subj]){
			subjects[subj]=new Array(loc[0].length);
			for(i=0;i<loc[0].length;i++){
				if(!subjects[subj][i])subjects[subj][i]={};
				for(j=0;j<loc.length;j++){
					if(subjects[subj][i][loc[j][i]]){
						subjects[subj][i][loc[j][i]].push(timetaken/loc.length);
					} else {
						subjects[subj][i][loc[j][i]]=[timetaken/loc.length];
					}
				}
			}
		}
	};

	this.estimate=function(hwdesc){
		var subj,loc;
		assert(hwdesc instanceof HomeworkDescription);
		subj=hwdesc.subject;
		loc=hwdesc.location;
		var total=0;
		loc.forEach(function(locitem){
			total+=rms(subjects[subj].map(function(sitem,i){
				console.log(sitem,locitem[i],sitem[locitem[i]]);
				return rms(sitem[locitem[i]]);
			}));
		});
		return total;
	};

	this.persistable=function(){
		return subjects;
	}
}


function rms(arr){
	var sum,i,len;
	sum=0;
	len=arr.length;
	for(i=0;i<len;i++)sum+=arr[i]*arr[i];
	return Math.sqrt(sum/len);
}



module.exports={
	HomeworkDescription:HomeworkDescription,
	Planner:Planner
};

/*
var REQ=require("./planner");
var h=REQ.HomeworkDescription();
h.subject="ne";
h.location=[[1,2],[1,3]];
var P=REQ.Planner();
P.learn(h,10);
console.log(util.inspect(P.persistable(),{depth:10}));
P.estimate(h);
*/
