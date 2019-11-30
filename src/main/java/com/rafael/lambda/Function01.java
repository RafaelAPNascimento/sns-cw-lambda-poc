package com.rafael.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class Function01 implements RequestHandler<Void, String>
{

    @Override
    public String handleRequest(Void input, Context context)
    {

        LambdaLogger logger = context.getLogger();
        logger.log("\n==================== Function01");
        logger.log("\n==================== input: "+input);
        return "============ F01 return ===================";
    }
}
