SELECT 
    username,
    platform,
    SUM(comments) AS comments,
    SUM(likes) AS likes,
    SUM(video_views) AS video_views,
    SUM(video_plays) AS video_plays
FROM 
    "creatorsdb"."metrics"
GROUP BY 
    username,
    platform
ORDER BY 
    username,
    platform;