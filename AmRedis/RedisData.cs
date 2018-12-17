using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using System.IO;
using Utf8Json;

namespace am
{

public class RedisData
{

    /*=========================================================*/

    // ClientCodeからのみ使用
    public class Request
    {
	[DataMember(Name = "role")]
	public string role { get; set; } = "server";
	[DataMember(Name = "mode")]
	public string mode { get; set; }
	[DataMember(Name = "k")]
	public string k { get; set; } = "";
	// Save Mode Only
	[DataMember(Name = "v")]
	public string v { get; set; } = "";
    }
    
    public class Response
    {
	[DataMember(Name = "status")]
	public string status { get; set; }	
	[DataMember(Name = "meta")]
	public string meta { get; set; } = "dummy";
	[DataMember(Name = "k")]
	public string k { get; set; } = "";
	[DataMember(Name = "v")]
	public string v { get; set; } = "";
    }
    
    /*=========================================================*/
    
    public RedisData(){
    }   
    
}
}
