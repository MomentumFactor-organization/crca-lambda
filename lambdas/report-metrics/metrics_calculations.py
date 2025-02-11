import pandas as pd


def aggregate_data(raw_metics):
    metrics_df = pd.DataFrame(raw_metics)
    result_metrics = {}
    metrics_df.drop(columns=["post_id","platform","username"])
    result_metrics = metrics_df.groupby(["username","platform"]).sum().drop(columns=["post_id"]).to_dict(orient="records")[0]
    # for col in metrics_df.columns:                        #Remove this lines?
    #     result_metrics[col] = metrics_df[col].sum()
    result_metrics["posts_count"] = metrics_df.shape[0]
    return result_metrics
    

def calculate_metrics(report_metrics, post_metrics):
    result_metrics = {}
    
    total_interactions = post_metrics["video_views"] + post_metrics["likes"] + post_metrics["comments"]
    followers = report_metrics["follower_count"]
    result_metrics["Reach"] = (total_interactions / followers) if followers != 0 else 0
    result_metrics["Followers"] = followers 
    result_metrics["Efficacy"]  = (total_interactions / post_metrics["likes"]) if post_metrics != 0 else 0
    return result_metrics
