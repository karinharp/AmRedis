using System;
using Amazon.Lambda.TestUtilities;
using Amazon.Lambda.Core;

namespace am {
    class Program {
	
        static void Main(string[] args){
	    _TestRun(new LambdaRedis(), new LambdaRedisArg(){ role = "server", mode = "set", k  = "foo", v = "bar" });
	    _TestRun(new LambdaRedis(), new LambdaRedisArg(){ role = "server", mode = "get", k  = "foo" });
	    TestRun(new LambdaRedis(), new LambdaRedisArg(){ role = "client", mode = "set", k  = "hoge", v = "mage" });
	    TestRun(new LambdaRedis(), new LambdaRedisArg(){ role = "client", mode = "get", k  = "hoge" });
        }
	
	static void TestRun<T_FUNC, T_ARG>(T_FUNC lambdaFunc, T_ARG lambdaArg)
	    where T_FUNC: LambdaBase<T_ARG>
	    where T_ARG: LambdaBaseArg
	{
	    Console.WriteLine(lambdaFunc.ToString() + " >> " + lambdaArg.role + " : " + lambdaArg.mode + " >> Test.");
	    var ret = lambdaFunc.Handler(lambdaArg, new TestLambdaContext());
	    Console.WriteLine("Ret > " +  ret);
	    Console.WriteLine("======================================================");
	}

        static void _TestRun<T_FUNC, T_ARG>(T_FUNC lambdaFunc, T_ARG lambdaArg)
            where T_FUNC: LambdaBase<T_ARG>
            where T_ARG: LambdaBaseArg
        {
            Console.WriteLine(lambdaFunc.ToString() + " >> " + lambdaArg.role + " : " + lambdaArg.mode + " >> Bypass.");
            Console.WriteLine("======================================================");
        }
    }
}
