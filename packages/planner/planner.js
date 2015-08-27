/*
 * simplyHomework plan algorithm and stuff.
 * @author simply
 * @module planner
 */

var _ = _ || require('lodash');

var assert = function (val) {
	if (!val) throw new Error("AssertionError: false == true");
};

function subjectGrade(subjid){
	return Math.random()*9+1; //TODO:: Get average grade of student for this subject
}

HomeworkDescription=function(){
	if(!(this instanceof HomeworkDescription))return new HomeworkDescription(arguments[0],arguments[1],arguments[2]);

	//A unique identifier for a subject. Can be pretty much anything, lest it's a primitive type
	//  and unique and fixed, i.e. there is only one identifier per subject and only one subject per identifier.
	this.subject=arguments.length>0?arguments[0]:null;

	//Items in `location` can be multiple things, e.g.
	//- [chapter,paragraph,exercise]
	//- [bookid,page,exercise]
	//- [chapter,exercise]
	//- [bookid,page]
	//In general, anything that can be expressed in a sequence of integers that specifies the location.
	//  (Actually, they should be index paths — think NSIndexPath)
	//The `location` property contains an array of those, because homework can be multiple exercises, for example.
	//Please make the array contiguous, though; don't mix indexing conventions! (!) (!!)
	this.location=arguments.length>1?arguments[1]:[];

	//A Date indicating when this homework is due
	this.duedate=arguments.length>2?arguments[2]:null;
};

Planner=function(){
	if(!(this instanceof Planner))return new Planner(arguments[0]);

	this.isPlannerObject=true;

	//PREV: Object[subject id][location index path item][value of the loc. idxp. item][samples of time taken]
	//Object[subject id][loc item 0][loc item 1]...[loc item n] = time taken for that index path
	var subjects={}; //The Cache

	//`timetaken` in any unit you find convenient; but please be consistent. Suggestion: seconds.
	this.learn=function(hwdesc,timetaken){
		var i,j,idx,subj,loc;
		assert(hwdesc instanceof HomeworkDescription);
		subj=hwdesc.subject;
		loc=hwdesc.location;
		assert(loc.length!=0);
		if(!subjects[subj]){
			subjects[subj]={};
		}
		var itemref;
		for(i=0;i<loc.length;i++){
			itemref=subjects[subj];
			for(j=0;j<loc[i].length;j++){
				if(j==loc[i].length-1){
					itemref[loc[i][j]]=timetaken/hwdesc.location.length;
				} else if(!itemref[loc[i][j]]){
					itemref[loc[i][j]]={};
				}
				itemref=itemref[loc[i][j]];
			}
		}
	};

	this.generalSubjectEstimate=function(subjid){
		var grade=subjectGrade(subjid);
		return 3600*3/2-3600*grade;
	};

	function estimateSingle(hwdesc){
		assert(hwdesc instanceof HomeworkDescription);
		assert(hwdesc.location.length==1);
		if(!subjects[hwdesc.subject]){
			return this.generalSubjectEstimate(hwdesc.subject);
		}
		var i,itemref=subjects[hwdesc.subject];
		for(i=0;i<hwdesc.location[0].length;i++){
			if(itemref[hwdesc.location[0][i]]==null)break;
			itemref=itemref[hwdesc.location[0][i]];
		}
		if(i==hwdesc.location[0].length)return itemref;
		var key,timearr=[];
		for(key in itemref){
			timearr.push(itemref[key]);
		}
		return rms(timearr);
	}

	this.estimate=function(hwdesc){
		var subj,loc;
		//assert(hwdesc instanceof HomeworkDescription);
		return sum(hwdesc.location.map(function(loc){
			return estimateSingle(HomeworkDescription(hwdesc.subject,[loc]));
		}));
	};

	this.persistable=function(){
		return _.cloneDeep(subjects);
	};
	this.frompersistable=function(subj){
		if(subj.isPlannerObject===true) //they persisted the whole object ._.
			subjects=subj.persistable();
		else subjects=_.cloneDeep(subj);
	};

	this.availableTimeConvert=function(code){
		// return [0,30*60,90*60,180*60][code];
		return (15*code*code+15*code)*60;
	};

	//`items` is an Array of HomeworkDescriptions
	//`available` is an Array of ints, specifying how much time (in the time unit) there is available
	//  on that day of the plan region.
	//`today` is a Date which the planner uses as "today"
	this.plan=function(items,available,today){
		items=_.cloneDeep(items); //we'll modify them for our own needs
		var ndays=available.length;
		var needed=new Array(ndays);
		var i;
		for(i=0;i<ndays;i++){
			available[i]=this.availableTimeConvert(available[i]);
			needed[i]=this.estimate(items[i]);
		}
		console.log("available =",available," needed =",needed);
		today=startOfDay(today);
		var maxdiff=0;
		for(i=0;i<items.length;i++){
			items[i].duedate=startOfDay(items[i].duedate);
			items[i].duediff=diffDays(today,items[i].duedate);
			if(items[i].duediff<0)items[i].duediff=0; //you're a bit late son
			maxdiff=Math.max(maxdiff,items[i].duediff);
		}
		var dueInDays=new Array(maxdiff+1);
		for(i=0;i<=maxdiff;i++)dueInDays[i]=[];
		for(i=0;i<items.length;i++){
			dueInDays[items[i].duediff].push({item:items[i],needed:needed[i]});
		}
		for(i=0;i<dueInDays.length;i++){
			dueInDays[i].sort(function(a,b){return a.needed<b.needed;}); //descending sort on needed time
		}
		var schedule=new Array(maxdiff);
		var daylength=new Array(maxdiff);
		for(i=0;i<maxdiff;i++){
			schedule[i]=[];
			daylength[i]=0;
		}
		var workingForDay;
		var day,it;
		workingForDay=0;
		while(true){
			while(workingForDay<dueInDays.length&&dueInDays[workingForDay].length==0)workingForDay++;
			if(workingForDay>=dueInDays.length)break; //done!
			console.log("day:",dueInDays[workingForDay]);
			it=dueInDays[workingForDay].shift();
			console.log("it =",it);
			console.log("daylength[0]="+daylength[0]+" it.needed="+it.needed+" available[0]="+available[0]);
			for(day=0;day<it.item.duediff;day++){
				if(daylength[day]+it.needed<=available[day])break;
			}
			if(day==it.item.duediff)assert(false); //TODO FIX STUFF THAT DOESN'T FIT
			schedule[day].push(it.item);
			daylength[day]+=it.needed;
		}
		var ret={};
		for(i=0;i<schedule.length;i++){
			if(schedule[i].length==0)continue;
			ret[addDays(today,i)]=schedule[i];
		}
		return ret;
	};



	if(arguments.length==1)subjects=_.cloneDeep(arguments[0]); //from a persist source
};


function startOfDay(date){
	return new Date(date.getFullYear(),date.getMonth(),date.getDate());
}
function addDays(date,ndays){
	return new Date(date.getTime()+ndays*24*3600*1000);
}
function diffDays(d1,d2){
	return ~~((d2.getTime()-d1.getTime())/(24*3600*1000));
}

function rms(arr){
	var sum,i,len;
	sum=0;
	len=arr.length;
	for(i=0;i<len;i++)sum+=arr[i]*arr[i];
	return Math.sqrt(sum/len);
}
function sum(arr){
	var sum,i,len;
	sum=0;
	len=arr.length;
	for(i=0;i<len;i++)sum+=arr[i];
	return sum;
}

if(typeof Meteor=="undefined"){
	module.exports={
		HomeworkDescription:HomeworkDescription,
		Planner:Planner
	};
}

/*
REQ=require("./planner")
H=REQ.HomeworkDescription
P=REQ.Planner
function hh(s,l){var h=new H;h.subject=s;h.location=l;return h;}
function inspect(o){console.log(util.inspect(o,{depth:8}));}
function startOfDay(date){return new Date(date.getFullYear(),date.getMonth(),date.getDate());}
function addDays(date,ndays){return new Date(date.getTime()+ndays*24*3600*1000);}
p=new P
p.learn(hh("ne",[[1,1],[1,2]]),100)
p.learn(hh("ne",[[1,5]]),40)
inspect(p.persistable())
p.estimate(hh("ne",[[1,5]]))
p.estimate(hh("ne",[[1,4]]))
p.plan([H("ne",[[1,2]],addDays(startOfDay(new Date),2)),H("ne",[[1,1],[1,5]],addDays(startOfDay(new Date),1))],[1,1],new Date)
*/
